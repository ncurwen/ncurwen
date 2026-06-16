module SiteData
  module_function

  def portfolio = load(:portfolio)
  def tech_stack = load(:tech_stack)
  def garden_notes = load(:garden_notes)
  def work_history = load(:work_history)
  def education = load(:education)

  def garden_images
    cache[:garden_images] ||= Dir.glob(Rails.root.join("app/assets/images/garden/**/*.{jpg,jpeg,JPG,JPEG,png,PNG}"))
      .sort
      .map do |path|
        basename = File.basename(path)
        rel_path = path.sub("#{Rails.root.join("app/assets/images/")}", "")
        date = basename.match(/(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})/) do |m|
          "#{m[1]}-#{m[2]}-#{m[3]} #{m[4]}:#{m[5]}"
        end
        { path: rel_path, date: date, basename: File.basename(basename, ".*") }
      end
  end

  def load(name)
    cache[name] ||= YAML.safe_load_file(
      Rails.root.join("config/#{name}.yml"),
      permitted_classes: [ Date, Symbol ],
      aliases: true
    ).deep_symbolize_keys
  end

  def cache
    @cache ||= {}
  end

  def reset!
    @cache = {}
  end
end
