require "test_helper"
require "view_component/test_helpers"

class WeddingRsvpControlsComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  def render_controls(guest)
    render_inline(Wedding::RsvpControlsComponent.new(guest: guest, token: guests(:alice).token))
  end

  test "posts to the guest's RSVP path using the viewer's token" do
    render_controls(guests(:bob))

    assert_selector "form[action='#{invitation_path(token: guests(:alice).token, id: guests(:bob).id)}']",
                    count: 2, visible: :all
  end

  test "submits as PATCH rather than POST" do
    render_controls(guests(:bob))

    assert_selector "input[name='_method'][value='patch']", visible: :all, minimum: 2
  end

  test "offers accept and decline, each carrying its status" do
    render_controls(guests(:bob))

    assert_selector "input[name='status'][value='yes']", visible: :all
    assert_selector "input[name='status'][value='no']", visible: :all
  end

  test "offers accept and decline only, with no way to clear an answer" do
    [ guests(:bob), guests(:alice), guests(:carol) ].each do |guest|
      render_controls(guest)

      assert_no_selector "input[name='status'][value='unknown']", visible: :all
      assert_no_text "Clear"
      assert_selector "form", count: 2, visible: :all
    end
  end

  # Without this the page silently stops morphing once a guest has followed the
  # hero's "#rsvp" link, and every answer jumps them back to the top.
  test "pins the Turbo visit action so a fragment in the URL can't break morphing" do
    render_controls(guests(:bob))

    assert_selector "button[data-turbo-action='replace']", count: 2
  end

  test "marks the current answer as pressed for assistive tech" do
    render_controls(guests(:alice))

    assert_selector "button[aria-pressed='true']", count: 1
    assert_selector "button.btn-primary[aria-pressed='true']"
  end

  # The accept button always carries the primary colour — it is the one thing the
  # page is asking for. It only becomes *filled* once the guest has accepted.
  test "fills the accept button only once the guest has accepted" do
    render_controls(guests(:alice))
    assert_selector "button.btn-primary:not(.btn-outline)[aria-pressed='true']", text: "Joyfully accepts"
  end

  # The filled button says the same thing, but a week after answering it is too
  # quiet to recognise. This line is what a returning guest actually reads.
  test "states the standing answer in words, for every status" do
    {
      alice: "Down as coming.",
      carol: "Down as unable to come.",
      bob: "No answer yet."
    }.each do |fixture, expected|
      render_controls(guests(fixture))

      assert_text expected
    end
  end

  test "leaves the accept button outlined while the answer is no" do
    render_controls(guests(:carol))

    assert_selector "button.btn-outline.btn-primary", text: "Joyfully accepts"
    assert_no_selector "button.btn-primary:not(.btn-outline)"
    assert_selector "button.btn-neutral[aria-pressed='true']", text: "Regretfully declines"
  end

  # The confetti hangs off the accept form's own submit event rather than the flash.
  # Driving it from the flash would also fire it on the broadcast morph that every
  # other open invitation receives — the whole household would get confetti for one
  # person's answer.
  test "only the accept form celebrates" do
    render_controls(guests(:bob))

    forms = page.all("form", visible: :all)
    accept, decline = forms

    assert_equal "wedding--rsvp-controls-component", accept["data-controller"]
    assert_equal "turbo:submit-end->wedding--rsvp-controls-component#celebrate", accept["data-action"]
    assert_nil decline["data-controller"]
  end

  # Pairs with the confetti, and carries the whole "that registered" signal on the
  # decline button, which gets no burst.
  test "marks the answer just given so it can pop" do
    render_controls(guests(:alice))
    assert_selector "button.wedding-answered", text: "Joyfully accepts", count: 1

    render_controls(guests(:bob))
    assert_no_selector "button.wedding-answered"
  end
end
