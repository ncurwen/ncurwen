module SiteData
  module_function

  def tech_stack = load(:tech_stack)
  def garden_notes = load(:garden_notes)
  def work_history = load(:work_history)
  def education = load(:education)

  def garden_images
    return scan_garden_images unless cache_enabled?

    cache[:garden_images] ||= scan_garden_images
  end

  def scan_garden_images
    Dir.glob(Rails.root.join("app/assets/images/garden/**/*.{jpg,jpeg,JPG,JPEG,png,PNG}"))
      .map do |path|
        basename = File.basename(path)
        rel_path = path.sub("#{Rails.root.join("app/assets/images/")}", "")
        m = basename.match(/(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})/)
        date = m && "#{m[1]}-#{m[2]}-#{m[3]} #{m[4]}:#{m[5]}"
        year = (m && m[1]) || rel_path[%r{garden/(\d{4})/}, 1]
        sort_key = m ? "#{m[1]}#{m[2]}#{m[3]}#{m[4]}#{m[5]}" : "#{year}00000000"
        { path: rel_path, date: date, basename: File.basename(basename, ".*"), year: year, sort_key: sort_key }
      end
      .sort_by { |img| img[:sort_key] }
      .reverse
  end

  def load(name)
    return read(name) unless cache_enabled?

    cache[name] ||= read(name)
  end

  DATA_DIR = Rails.root.join("config/site_data").freeze
  def read(name)
    path = DATA_DIR.join("#{name}.yml")
    raise ArgumentError, "Missing site data file: #{path}" unless File.exist?(path)

    YAML.safe_load_file(
      path,
      permitted_classes: [ Date, Symbol ],
      aliases: true
    ).deep_symbolize_keys
  end

  # Cache in production/test; reload from disk every request in development so
  # YAML edits show up without a server restart.
  def cache_enabled?
    !Rails.env.development?
  end

  def cache
    @cache ||= {}
  end

  def reset!
    @cache = {}
  end
end
