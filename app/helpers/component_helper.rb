module ComponentHelper
  def education_tag(...) = render EducationComponent.new(...)
  def copy_tag(...) = render CopyComponent.new(...)
  def photo_gallery_tag(...) = render PhotoGalleryComponent.new(...)
  def table_of_contents_tag(...) = render TableOfContentsComponent.new(...)
  def theme_toggle_tag(...) = render ThemeToggleComponent.new(...)
  def work_history_tag(...) = render WorkHistoryComponent.new(...)
end
