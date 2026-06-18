# Backs the static pages with data from config/site_data/*.yml.
# SiteData.fetch(:education) returns a file's array of rows.
# See SiteData::Loader and SiteData::Validator.
module SiteData
  Error = Class.new(StandardError)
  MissingFile = Class.new(Error)
  InvalidData = Class.new(Error)

  class << self
    def fetch(name) = cached(name) { Loader.call(name) }

    private

    # Recompute every call in development so YAML edits show up without a
    # restart; memoise everywhere else.
    def cached(key)
      return yield if Rails.env.development?

      (@cache ||= {})[key] ||= yield
    end
  end
end
