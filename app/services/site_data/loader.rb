module SiteData
  # Reads one config/site_data/<name>.yml file and returns its array of rows.
  # The argument is the file's basename as a Symbol, e.g. Loader.call(:education).
  #
  # The data is validated while editing (development reparses every request) and
  # in CI (test); production skips it since CI already validated the same
  # committed files. Caching lives in SiteData.fetch, not here.
  class Loader < ApplicationService
    DIR = Rails.root.join("config/site_data").freeze

    def initialize(name)
      @name = name
    end

    def call
      data = read
      Validator.call(name, data) if Rails.env.local?
      data.fetch(Schema::ROOT) { raise InvalidData, "#{name}: missing '#{Schema::ROOT}' key" }
    end

    private

    attr_reader :name

    def read
      path = DIR.join("#{name}.yml")
      raise MissingFile, "Missing site data file: #{path}" unless File.exist?(path)

      YAML.safe_load_file(
        path,
        permitted_classes: [ Date, Symbol ],
        aliases: true
      ).deep_symbolize_keys
    end
  end
end
