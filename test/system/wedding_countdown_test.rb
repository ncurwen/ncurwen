require "application_system_test_case"

class WeddingCountdownTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  # Everything here uses `visible: :all`: daisyUI sets `visibility: hidden` on the
  # countdown's children and paints the digits with ::before/::after, so Capybara
  # correctly considers the spans invisible even when the counter is working.

  # The acceptance test for the whole progressive-enhancement design. daisyUI paints
  # the digits from a `--value` custom property, and our CSP has no `unsafe-inline`
  # for style-src — a nonce doesn't cover style *attributes* — so the server can't
  # emit it and the CSSOM is the only route. If this fails, the counter is blank for
  # every guest and nothing else on the page would tell you.
  test "the countdown fills in its digits from JavaScript" do
    visit invitations_path(token: guests(:bob).token)

    assert_selector "[data-wedding--countdown-component-target='days']", visible: :all
    assert_equal Wedding.days_away.to_s, countdown_value("days")

    # Hours/minutes/seconds are whatever they are; that they're set at all is what
    # proves setProperty ran and wasn't refused.
    %w[hours minutes seconds].each do |unit|
      assert_match(/\A\d+\z/, countdown_value(unit), "#{unit} was never given a --value")
    end
  end

  test "the ticking counter replaces the sentence, but keeps it for screen readers" do
    visit invitations_path(token: guests(:bob).token)

    assert_selector "[data-wedding--countdown-component-target='live']:not(.hidden)"
    # Still in the DOM and still correct — just no longer the visual answer. A seconds
    # counter in a live region would be unusable, so this is what assistive tech reads.
    assert_selector "[data-wedding--countdown-component-target='sentence'].sr-only",
                    text: "#{Wedding.days_away} days to go", visible: :all
  end

  # Turbo morphs this page whenever anyone RSVPs, and morphing diffs attributes — it
  # reverts both the classes and the `--value` the controller set. Guards the outcome
  # rather than the mechanism: the one-second interval would also recover from this,
  # so what's asserted is that a broadcast leaves a working counter behind.
  test "the countdown survives someone else's RSVP arriving by broadcast" do
    visit invitations_path(token: guests(:bob).token)
    assert_selector "[data-wedding--countdown-component-target='days']", visible: :all

    perform_enqueued_jobs { guests(:carol).update!(status: "yes") }

    assert_selector ".badge-success", text: "Coming", minimum: 2
    assert_selector "[data-wedding--countdown-component-target='live']:not(.hidden)"
    assert_equal Wedding.days_away.to_s, countdown_value("days")
  end

  private

  def countdown_value(unit)
    page.evaluate_script(
      "document.querySelector(\"[data-wedding--countdown-component-target='#{unit}']\")" \
      ".style.getPropertyValue('--value')"
    ).to_s.strip
  end
end
