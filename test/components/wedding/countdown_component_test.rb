require "test_helper"
require "view_component/test_helpers"

class WeddingCountdownComponentTest < ViewComponent::TestCase
  def render_countdown(days:, from: Time.zone.local(2026, 9, 3, 12, 0))
    starts_at = from + days.days
    travel_to(from) { render_inline(Wedding::CountdownComponent.new(starts_at: starts_at, ends_at: starts_at + 6.hours)) }
  end

  # The whole reason this component is progressive enhancement rather than plain
  # markup. daisyUI's countdown needs `--value`, our CSP has no unsafe-inline for
  # style-src, and a nonce does not cover style *attributes* — so a server-rendered
  # `style="--value:…"` is blocked and the counter comes up blank. If this ever fails,
  # the digits have silently stopped rendering for every guest.
  test "renders no inline style attribute" do
    render_countdown(days: 282)

    assert_no_selector "[style]", visible: :all
  end

  test "states the day count in words for no-JS and for screen readers" do
    render_countdown(days: 282)

    assert_text "282 days to go"
  end

  test "delimits large day counts" do
    render_countdown(days: 400)

    assert_text "400 days to go"
  end

  test "singular on the last day but one" do
    render_countdown(days: 1)

    assert_text "1 day to go"
  end

  test "offers the ticking counter with the units the controller fills in" do
    render_countdown(days: 282)

    assert_selector "[data-controller='wedding--countdown-component']"
    %w[days hours minutes seconds].each do |unit|
      assert_selector "[data-wedding--countdown-component-target='#{unit}']"
    end
  end

  # daisyUI's countdown does mod(--value, 1000), so a four-digit day count would
  # render as its last three digits. The sentence is the honest answer there.
  test "declines to tick beyond what daisyUI can display" do
    render_countdown(days: 1200)

    assert_text "1,200 days to go"
    assert_no_selector "[data-wedding--countdown-component-target='days']"
  end

  test "says today rather than zero on the day" do
    render_countdown(days: 0)

    assert_text "It's today!"
    assert_no_selector "[data-wedding--countdown-component-target='days']"
  end

  test "renders nothing once the party is over" do
    starts_at = Time.zone.local(2026, 9, 1, 17, 0)

    render_inline(Wedding::CountdownComponent.new(starts_at: starts_at, ends_at: starts_at + 6.hours))

    assert_no_selector ".wedding-countdown"
  end
end
