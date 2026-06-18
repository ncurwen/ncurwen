require "test_helper"
require "view_component/test_helpers"

class PhotoGalleryComponentTest < ViewComponent::TestCase
  # Use a real on-disk image so Propshaft can resolve the asset path during render.
  REAL_PATH_A = "garden/2022/IMG_20220714_165114.HEIC_compressed.JPEG"
  REAL_PATH_B = "garden/2022/IMG_20220603_140830.HEIC_compressed.JPEG"

  def image(path: REAL_PATH_A, date: "2024-06-15 09:30", basename: "20240615_093045_one", year: "2024")
    { path: path, date: date, basename: basename, year: year }
  end

  test "renders nothing when images are empty" do
    render_inline(PhotoGalleryComponent.new(images: []))

    assert_no_selector "section[data-controller='photo-gallery-component']"
  end

  test "embeds gallery data as JSON on the section" do
    images = [
      image(path: REAL_PATH_A, date: "2024-06-15 09:30", basename: "a", year: "2024"),
      image(path: REAL_PATH_B, date: nil, basename: "b", year: "2022")
    ]

    render_inline(PhotoGalleryComponent.new(images: images))

    raw = page.find("section[data-controller='photo-gallery-component']")["data-photo-gallery-component-images-value"]
    parsed = JSON.parse(raw)

    assert_equal 2, parsed.length
    assert_equal %w[url date basename year season], parsed.first.keys
    assert_match %r{IMG_20220714_165114}, parsed.first["url"]
    assert_equal "2024-06-15 09:30", parsed.first["date"]
    assert_nil parsed.last["date"]
  end

  test "renders a clickable open button for the hero and each grid image" do
    images = [
      image(path: REAL_PATH_A, basename: "a", year: "2022"),
      image(path: REAL_PATH_B, basename: "b", year: "2022")
    ]

    render_inline(PhotoGalleryComponent.new(images: images))

    # One hero button (the latest frame) plus one button per grid image.
    assert_selector "button[data-action='click->photo-gallery-component#open']", count: images.length + 1
  end
end
