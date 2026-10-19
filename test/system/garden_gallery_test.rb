require "application_system_test_case"

class GardenGalleryTest < ApplicationSystemTestCase
  FRAME = "dialog [data-photo-gallery-lightbox-component-target='image']".freeze

  def tile(n)
    all("button[data-photo-gallery-lightbox-component-index-param]")[n]
  end

  def frame_src
    find(FRAME, visible: :all)[:src].to_s.split("/").last
  end

  test "the lightbox never shows the previous photo when reopened on another" do
    visit garden_path

    tile(1).click
    assert_selector "dialog[open]"
    assert_no_selector "#{FRAME}.opacity-0", visible: :all
    first_photo = frame_src

    find("button[aria-label='Close gallery']").click
    assert_no_selector "dialog[open]"

    # An <img> keeps painting its old bitmap until the replacement decodes, and
    # src is updated long before that — so checking src proves nothing. What has
    # to hold is that the frame is *blanked* the instant a new photo is asked
    # for. Click and read the class in one synchronous turn: render() adds the
    # marker inline, and only clears it once decode() settles a microtask later,
    # so this reads the state the viewer would otherwise have seen the old photo in.
    blanked, shimmering = page.evaluate_script(<<~JS)
      (() => {
        document.querySelectorAll("button[data-photo-gallery-lightbox-component-index-param]")[5].click();
        return [
          document.querySelector("dialog [data-photo-gallery-lightbox-component-target='image']")
                  .classList.contains("opacity-0"),
          document.querySelector("dialog [data-photo-gallery-lightbox-component-target='frame']")
                  .classList.contains("skeleton")
        ];
      })()
    JS
    assert blanked, "the frame must blank the moment a different photo is opened"
    assert shimmering, "the skeleton loader stands in while the photo decodes"

    # …and it comes back showing the new photo, not the one just closed.
    assert_no_selector "#{FRAME}.opacity-0", visible: :all
    assert_no_selector "dialog [data-photo-gallery-lightbox-component-target='frame'].skeleton", visible: :all
    refute_equal first_photo, frame_src, "reopened on a different photo"
  end

  test "arrow keys step through photos without leaving the frame blank" do
    visit garden_path

    tile(1).click
    assert_selector "dialog[open]"
    assert_no_selector "#{FRAME}.opacity-0", visible: :all
    opened = frame_src

    find("dialog[open]").send_keys(:right)
    assert_no_selector "#{FRAME}.opacity-0", visible: :all
    refute_equal opened, frame_src, "moved to the next photo"

    find("dialog[open]").send_keys(:left)
    assert_no_selector "#{FRAME}.opacity-0", visible: :all
    assert_equal opened, frame_src, "came back to the one we started on"
  end

  test "grid tiles serve the generated thumbnails, not the originals" do
    visit garden_path

    # Guards the whole point of the derivative pipeline: a regression that drops
    # the <source> would silently go back to shipping ~1.1 MB per tile.
    assert_selector "[data-photo-gallery-filter-component-target='tile'] source[type='image/webp']",
                    visible: :all, minimum: 1
  end
end
