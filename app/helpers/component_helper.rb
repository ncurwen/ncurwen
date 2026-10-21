# Site-wide components. The invitation's own three (`countdown_tag`,
# `guest_list_tag`, `rsvp_controls_tag`) live in WeddingHelper so they can be
# removed with the rest of it; `flash_tag` and `theme_toggle_tag` are shared and
# stay here.
module ComponentHelper
  def education_tag(...) = render EducationComponent.new(...)
  def copy_tag(...) = render CopyComponent.new(...)
  def flash_tag(...) = render FlashComponent.new(...)
  def photo_gallery_tag(...) = render PhotoGalleryComponent.new(...)
  def table_of_contents_tag(...) = render TableOfContentsComponent.new(...)
  def theme_toggle_tag(...) = render ThemeToggleComponent.new(...)
  def work_history_tag(...) = render WorkHistoryComponent.new(...)
end
