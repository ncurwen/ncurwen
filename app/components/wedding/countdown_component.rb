# The "how long now?" counter under the hero date.
#
# Progressive enhancement, and it has to be: daisyUI's `.countdown` paints its digits
# entirely from `::before`/`::after` driven by a `--value` custom property, with the
# span's own text set to `visibility: hidden`. Our CSP has no `unsafe-inline` for
# style-src (and a nonce does not whitelist `style` *attributes*), so the server
# cannot emit `style="--value:282"` — it would be blocked and the counter would render
# blank. So the server renders a plain sentence, and the Stimulus controller swaps in
# the ticking version once it can set `--value` through the CSSOM, which CSP does not
# police.
#
# The sentence never leaves the DOM: with JS it becomes `sr-only`, so screen readers
# get "282 days to go" once instead of a seconds counter shouting into a live region.
module Wedding
  class CountdownComponent < ApplicationComponent
    # daisyUI's countdown does `mod(--value, 1000)`, so a four-digit day count would
    # silently render as its last three digits. Beyond this we stay on the sentence.
    MAX_COUNTDOWN_DAYS = 999

    def initialize(starts_at: Wedding::STARTS_AT, ends_at: Wedding::ENDS_AT)
      @starts_at = starts_at
      @ends_at = ends_at
    end

    # Nothing to count once the party is over.
    def render? = Time.current < ends_at

    private

    attr_reader :starts_at, :ends_at

    # Reads the injected `starts_at`, not the constant — the component is told which
    # date it's counting to, and the tests inject their own.
    def days_away = Wedding.days_away(to: starts_at)

    def today? = days_away.zero?

    # Too far out for the component to render honestly; the sentence stands alone.
    def too_far_out? = days_away > MAX_COUNTDOWN_DAYS

    # Exposed for the template, which would otherwise have to name the constant
    # through its full namespace.
    def max_countdown_days = MAX_COUNTDOWN_DAYS

    # Whether the ticking version is worth offering at all.
    def enhanceable? = !today? && !too_far_out?

    def sentence
      return "It's today!" if today?

      "#{ActiveSupport::NumberHelper.number_to_delimited(days_away)} " \
        "#{'day'.pluralize(days_away)} to go"
    end

    # Each cell of the ticking counter: [label, dom id fragment].
    def units = %w[days hours minutes seconds]
  end
end
