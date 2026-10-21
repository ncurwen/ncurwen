require "application_system_test_case"

class WeddingCelebrationTest < ApplicationSystemTestCase
  # Asserts on pixels actually painted, not just that the code path ran. Three separate
  # bugs got through a weaker check: the canvas being replaced by the morph, the oklch
  # theme tokens converting to garbage hex, and the origin being measured from a
  # `display: contents` form whose bounding box is all zeros. Each one left the burst
  # invisible while every other signal still looked healthy.
  test "accepting paints confetti that survives the redirect's morph" do
    visit invitations_path(token: guests(:bob).token)

    assert_equal 0, confetti_pixels

    within_card("Bob Attending") { click_button "Joyfully accepts" }
    within_card("Bob Attending") { assert_text "Down as coming." }

    assert_operator painted_pixels, :>, 0, "the confetti canvas was never painted"
  end

  # Declining is a perfectly good answer, but it isn't a celebration. The controller is
  # attached to the accept form only, and this is what holds that in place.
  test "declining does not" do
    visit invitations_path(token: guests(:bob).token)

    within_card("Bob Attending") { click_button "Regretfully declines" }
    within_card("Bob Attending") { assert_text "Down as unable to come." }

    assert_no_selector "[data-wedding-confetti][data-celebrating]", visible: :all
    assert_equal 0, confetti_pixels
  end

  # The burst is decoration on top of an answer that's already recorded, so suppressing
  # it must not take the RSVP with it.
  test "reduced motion suppresses the confetti but not the answer" do
    visit invitations_path(token: guests(:bob).token)

    # Cuprite's Chrome build doesn't expose Emulation.setEmulatedMedia, so stub the
    # query the controller actually asks.
    page.execute_script(<<~JS)
      window.matchMedia = (query) => ({
        matches: query.includes("prefers-reduced-motion"),
        media: query, addEventListener() {}, removeEventListener() {}
      })
    JS

    within_card("Bob Attending") { click_button "Joyfully accepts" }
    within_card("Bob Attending") { assert_text "Down as coming." }

    assert_predicate guests(:bob).reload, :yes?
    assert_no_selector "[data-wedding-confetti][data-celebrating]", visible: :all
    assert_equal 0, confetti_pixels
  end

  private

  def within_card(name, &block)
    within(find("article.card", text: name, match: :first), &block)
  end

  # The particles are animated, so a single sample can land between frames. Poll until
  # something has been drawn, or give up and let the caller assert on zero.
  def painted_pixels
    deadline = Time.current + 3.seconds
    pixels = 0
    pixels = confetti_pixels while pixels.zero? && Time.current < deadline
    pixels
  end

  def confetti_pixels
    page.evaluate_script(<<~JS).to_i
      (() => {
        const canvas = document.querySelector("[data-wedding-confetti]")
        if (!canvas || !canvas.width) return 0
        const data = canvas.getContext("2d").getImageData(0, 0, canvas.width, canvas.height).data
        let painted = 0
        for (let i = 3; i < data.length; i += 4) if (data[i] > 0) painted++
        return painted
      })()
    JS
  end
end
