module ComponentHelper
  def education_tag(...) = render EducationComponent.new(...)
  def guest_list_tag(...) = render GuestListComponent.new(...)
  def copy_tag(...) = render CopyComponent.new(...)
  def flash_tag(...) = render FlashComponent.new(...)
  def photo_gallery_tag(...) = render PhotoGalleryComponent.new(...)
  def rsvp_controls_tag(...) = render RsvpControlsComponent.new(...)
  def table_of_contents_tag(...) = render TableOfContentsComponent.new(...)
  def theme_toggle_tag(...) = render ThemeToggleComponent.new(...)
  def work_history_tag(...) = render WorkHistoryComponent.new(...)
end
