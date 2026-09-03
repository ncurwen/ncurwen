require "application_system_test_case"

class WeddingRsvpTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test "a guest RSVPs and the answer sticks" do
    visit invitations_path(token: guests(:bob).token)

    assert_selector "h1"

    within_household_card("Bob Attending") { click_button "Joyfully accepts" }

    assert_selector ".badge-success", text: "Coming", minimum: 2
    assert_predicate guests(:bob).reload, :yes?
  end

  # The whole point of the change: the click has to visibly land, and the card
  # has to still say so on the next visit.
  test "an RSVP is confirmed by a toast and leaves the answer stated on the card" do
    visit invitations_path(token: guests(:bob).token)

    within_household_card("Bob Attending") { assert_text "No answer yet." }

    within_household_card("Bob Attending") { click_button "Joyfully accepts" }

    within(".toast") { assert_text "Bob Attending is down as coming." }
    within_household_card("Bob Attending") { assert_text "Down as coming." }
  end

  test "re-clicking the answer you already gave still confirms it" do
    visit invitations_path(token: guests(:alice).token)

    # Alice is already "yes"; this writes nothing, so only the toast can tell
    # her the click registered at all.
    within_household_card("Alice Attending") { click_button "Joyfully accepts" }

    within(".toast") { assert_text "Alice Attending is down as coming." }
  end

  # Turbo keeps [data-turbo-permanent] nodes through a morph, which is what stops
  # someone else's RSVP broadcast from yanking a toast the guest is still reading.
  test "a toast survives a broadcast refresh from another guest" do
    visit invitations_path(token: guests(:alice).token)

    within_household_card("Bob Attending") { click_button "Joyfully accepts" }
    within(".toast") { assert_text "Bob Attending is down as coming." }

    perform_enqueued_jobs { guests(:carol).update!(status: "yes") }

    assert_selector ".badge-success", text: "Coming", count: 3
    within(".toast") { assert_text "Bob Attending is down as coming." }
  end

  test "a guest can answer for someone else in their household" do
    visit invitations_path(token: guests(:alice).token)

    within_household_card("Bob Attending") { click_button "Regretfully declines" }

    assert_predicate guests(:bob).reload, :no?
  end

  test "the RSVP section covers the household but not other guests" do
    visit invitations_path(token: guests(:alice).token)

    within "#rsvp" do
      assert_text "Alice Attending"
      assert_text "Bob Attending"
      assert_no_text "Carol Elsewhere"
    end
  end

  # Regression: following the hero's "#rsvp" link puts a fragment in the URL.
  # Turbo infers its visit action by comparing hrefs, and the redirect back to
  # the fragment-less URL then looks like a different page — so it stopped
  # morphing and threw the guest back to the top of the invitation.
  test "answering after following the RSVP link morphs in place instead of jumping to the top" do
    visit invitations_path(token: guests(:bob).token)

    click_link "RSVP"
    assert_match(/#rsvp\z/, page.current_url)

    scrolled_to = page.evaluate_script("window.scrollY")
    assert_operator scrolled_to, :>, 0, "expected the anchor to have scrolled the page down"

    within_household_card("Bob Attending") { click_button "Joyfully accepts" }

    assert_predicate guests(:bob).reload, :yes?
    assert_selector ".badge-success", text: "Coming"

    # The morph keeps the reader where they were; a full re-render resets to 0.
    assert_operator page.evaluate_script("window.scrollY"), :>, 0,
                    "the page jumped back to the top instead of morphing in place"
  end

  # The point of the whole broadcast setup: an answer given in one browser shows
  # up in another without anyone reloading.
  test "an RSVP made elsewhere appears live, without a reload" do
    visit invitations_path(token: guests(:carol).token)

    assert_selector ".badge-ghost", text: "Unknown"

    # Stand in for another guest's browser. The model broadcasts a refresh on
    # commit, which Turbo morphs into this already-open page.
    perform_enqueued_jobs { guests(:bob).update!(status: "yes") }

    assert_selector ".badge-success", text: "Coming", count: 2
    assert_no_selector ".badge-ghost", text: "Unknown"
  end

  # The pop in wedding.css is an entry animation, so it only fires if the morph
  # *replaces* the badge rather than patching it. Both look identical in the HTML,
  # so probe the node itself: a JS property survives a morph and dies with a
  # replacement. This is the test that actually guards the animation.
  test "a changed badge is replaced on morph rather than patched, so the pop fires" do
    visit invitations_path(token: guests(:carol).token)

    before = "#guest-#{guests(:bob).id}-status-unknown"
    after  = "#guest-#{guests(:bob).id}-status-yes"

    assert_selector before
    page.execute_script("document.querySelector('#{before}').morphProbe = true")

    perform_enqueued_jobs { guests(:bob).update!(status: "yes") }

    assert_selector after
    assert_equal false, page.evaluate_script("document.querySelector('#{after}').morphProbe === true"),
                 "the badge was morphed in place instead of replaced, so its entry animation never runs"
  end

  private

  # The RSVP blocks and the guest list both mention a name, so scope to the card
  # in the RSVP section that carries this guest's buttons.
  def within_household_card(name, &block)
    within("#rsvp article.card", text: name, &block)
  end
end
