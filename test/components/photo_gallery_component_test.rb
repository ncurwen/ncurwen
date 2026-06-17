require "test_helper"
require "view_component/test_helpers"

class PhotoGalleryComponentTest < ViewComponent::TestCase
  # Use a real on-disk image so Propshaft can resolve the asset path during render.
  REAL_PATH_A = "garden/2022/IMG_20220714_165114.HEIC_compressed.JPEG"
  REAL_PATH_B = "garden/2022/IMG_20220603_140830.HEIC_compressed.JPEG"
  REAL_PATH_C = "garden/2022/IMG_20220826_185241_1.jpg_compressed.JPEG"

  def image(path: REAL_PATH_A, date: "2024-06-15 09:30", basename: "20240615_093045_one")
    { path: path, date: date, basename: basename }
  end

  test "renders nothing when images are empty" do
    render_inline(PhotoGalleryComponent.new(images: []))

    assert_no_selector "section[data-controller='gallery']"
  end

  test "renders one button per image" do
    images = [
      image(path: REAL_PATH_A, basename: "a"),
      image(path: REAL_PATH_B, basename: "b"),
      image(path: REAL_PATH_C, basename: "c")
    ]

    render_inline(PhotoGalleryComponent.new(images: images))

    assert_selector "button[data-action='click->gallery#open']", count: 3
  end

  test "marks the first image as the feature with a head badge" do
    images = [
      image(path: REAL_PATH_A, basename: "first"),
      image(path: REAL_PATH_B, basename: "second")
    ]

    render_inline(PhotoGalleryComponent.new(images: images))

    buttons = page.all("button[data-action='click->gallery#open']")
    assert_includes buttons.first[:class], "sm:col-span-2"
    refute_includes buttons.last[:class], "sm:col-span-2"
    assert_selector "span", text: "head", count: 1
  end

  test "embeds gallery data as JSON on the section" do
    images = [
      image(path: REAL_PATH_A, date: "2024-06-15 09:30", basename: "a"),
      image(path: REAL_PATH_B, date: nil, basename: "b")
    ]

    render_inline(PhotoGalleryComponent.new(images: images))

    raw = page.find("section[data-controller='gallery']")["data-gallery-images-value"]
    parsed = JSON.parse(raw)

    assert_equal 2, parsed.length
    assert_equal %w[url date basename], parsed.first.keys
    assert_match %r{IMG_20220714_165114}, parsed.first["url"]
    assert_equal "2024-06-15 09:30", parsed.first["date"]
    assert_nil parsed.last["date"]
  end

  test "renders date overlay only when image has a date" do
    images = [
      image(path: REAL_PATH_A, date: "2024-06-15 09:30", basename: "with-date"),
      image(path: REAL_PATH_B, date: nil, basename: "no-date")
    ]

    render_inline(PhotoGalleryComponent.new(images: images))

    assert_selector "span", text: "2024-06-15 09:30", count: 1
  end

  test "renders years label in header when at least one image has a date" do
    images = [
      image(path: REAL_PATH_A, date: "2024-06-15 09:30"),
      image(path: REAL_PATH_B, date: "2025-04-02 12:00")
    ]

    render_inline(PhotoGalleryComponent.new(images: images))

    assert_text "2 photos · 2024-2025"
  end

  test "omits years label when no images have dates" do
    images = [ image(path: REAL_PATH_A, date: nil, basename: "one") ]

    render_inline(PhotoGalleryComponent.new(images: images))

    header = page.find("section[data-controller='gallery'] > div.flex-wrap").text
    assert_includes header, "1 photos"
    refute_includes header, "·"
  end
end
