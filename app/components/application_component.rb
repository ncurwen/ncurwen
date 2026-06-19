class ApplicationComponent < ViewComponent::Base
  # Components don't get the view's helper methods as bare methods — only via the
  # `helpers` proxy. Delegate the specific ones our templates/classes call so they
  # read like a regular view (`image_tag`, `asset_path`, `table_of_contents_tag`,
  # `lucide_icon`).
  delegate :image_tag, :asset_path, :table_of_contents_tag, :lucide_icon, to: :helpers
end
