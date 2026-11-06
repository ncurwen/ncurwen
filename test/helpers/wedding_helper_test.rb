require "test_helper"

class WeddingHelperTest < ActionView::TestCase
  test "spells out the dietary shorthand for hover and screen readers" do
    assert_dom_equal %(<abbr title="Gluten-free" class="badge badge-sm badge-outline no-underline">GF</abbr>),
                     dietary_badge("GF")
  end

  test "an asterisk marks a dish with a suitable option rather than a suitable dish" do
    assert_dom_equal %(<abbr title="Vegetarian option available" class="badge badge-sm badge-outline no-underline">VEG*</abbr>),
                     dietary_badge("VEG*")
  end

  # A typo in the menu (say "VEGGIE") should fail loudly, not render a badge that
  # explains nothing.
  test "rejects a code it can't explain" do
    assert_raises(KeyError) { dietary_badge("VEGGIE") }
  end
end
