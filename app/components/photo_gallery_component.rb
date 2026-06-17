class PhotoGalleryComponent < ViewComponent::Base
  def initialize(images:)
    @images = images
  end

  def render?
    @images.any?
  end

  private

  attr_reader :images

  def gallery_data
    images.map { |img| { url: helpers.asset_path(img[:path]), date: img[:date], basename: img[:basename] } }
  end

  def years_label
    images.map { |i| i[:date]&.slice(0, 4) }.compact.uniq.sort.join("-")
  end
end
