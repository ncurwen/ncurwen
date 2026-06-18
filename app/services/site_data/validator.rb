module SiteData
  # Validates parsed YAML against Schema::SCHEMAS. Collects *every* problem and
  # raises a single InvalidData listing them by dotted path, e.g.
  # "work_history rows[1].roles[0].title: missing". Unknown keys are rejected so
  # a typo surfaces loudly instead of silently dropping its value.
  #
  #   SiteData::Validator.call(:work_history, data)
  class Validator < ApplicationService
    def initialize(name, data)
      @name = name
      @data = data
      @errors = []
    end

    def call
      spec = Schema::SCHEMAS.fetch(@name) { raise ArgumentError, "Unknown site data: #{@name.inspect}" }
      rows = @data.is_a?(Hash) ? @data[Schema::ROOT] : nil

      if rows.is_a?(Array)
        rows.each_with_index { |row, i| validate_row(row, spec, "#{Schema::ROOT}[#{i}]") }
      else
        @errors << "#{Schema::ROOT}: expected an array of rows"
      end

      return if @errors.empty?

      raise InvalidData, "#{@name} is invalid:\n  - #{@errors.join("\n  - ")}"
    end

    private

    def validate_row(row, spec, path)
      unless row.is_a?(Hash)
        @errors << "#{path}: expected a mapping"
        return
      end

      spec[:required]&.each do |field, type|
        if row.key?(field)
          validate_field(row[field], type, "#{path}.#{field}")
        else
          @errors << "#{path}.#{field}: missing"
        end
      end

      spec[:optional]&.each do |field, type|
        next unless row.key?(field) && !row[field].nil?

        validate_field(row[field], type, "#{path}.#{field}")
      end

      known = (spec[:required]&.keys || []) + (spec[:optional]&.keys || [])
      (row.keys - known).each { |field| @errors << "#{path}.#{field}: unknown key" }
    end

    def validate_field(value, type, path)
      if type.is_a?(Hash) # nested array of rows
        if value.is_a?(Array)
          value.each_with_index { |sub, i| validate_row(sub, type, "#{path}[#{i}]") }
        else
          @errors << "#{path}: expected an array of mappings"
        end
        return
      end

      case type
      when :str
        @errors << "#{path}: expected a string" unless value.is_a?(String)
      when :date
        @errors << "#{path}: expected a date" unless value.is_a?(Date)
      when :array
        if value.is_a?(Array)
          value.each_with_index do |item, i|
            @errors << "#{path}[#{i}]: expected a string" unless item.is_a?(String)
          end
        else
          @errors << "#{path}: expected an array of strings"
        end
      else
        raise ArgumentError, "Unknown schema type: #{type.inspect}"
      end
    end
  end
end
