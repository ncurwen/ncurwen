module SiteData
  module_function

  def portfolio = load(:portfolio)
  def tech_stack = load(:tech_stack)
  def garden_notes = load(:garden_notes)
  def work_history = load(:work_history)
  def education = load(:education)

  def load(name)
    cache[name] ||= YAML.safe_load_file(
      Rails.root.join("config/#{name}.yml"),
      permitted_classes: [Date, Symbol],
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
