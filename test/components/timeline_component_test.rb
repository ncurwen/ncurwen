require "test_helper"
require "view_component/test_helpers"

class TimelineComponentTest < ViewComponent::TestCase
  def entry(date: Date.new(2024, 6, 15), title: "Sowed peas", body: "Two rows in the back bed.", tag: "spring")
    { date: date, title: title, body: body, tag: tag }
  end

  test "renders nothing when entries are empty" do
    render_inline(TimelineComponent.new(entries: []))

    assert_no_selector "ul.timeline"
  end

  test "renders one li per entry" do
    render_inline(TimelineComponent.new(entries: [ entry, entry, entry ]))

    assert_selector "ul.timeline > li", count: 3
  end

  test "places hr dividers between but not around items" do
    render_inline(TimelineComponent.new(entries: [ entry, entry, entry ]))

    # 3 items → each non-edge gets an hr on each side; first li has 1 trailing hr,
    # middle li has 2, last li has 1 leading hr. Total = 4.
    assert_selector "ul.timeline > li > hr", count: 4

    first_li = page.find("ul.timeline > li:first-child")
    assert_equal 1, first_li.all("hr", visible: false).size

    last_li = page.find("ul.timeline > li:last-child")
    assert_equal 1, last_li.all("hr", visible: false).size
  end

  test "renders tag badge only when tag is present" do
    entries = [ entry(tag: "spring"), entry(tag: nil) ]

    render_inline(TimelineComponent.new(entries: entries))

    assert_selector "span.badge", text: "#spring", count: 1
  end

  test "renders date as YYYY-MM-DD inside a time element" do
    render_inline(TimelineComponent.new(entries: [ entry(date: Date.new(2024, 6, 15)) ]))

    assert_selector "time", text: "2024-06-15"
  end

  test "uses custom icon when provided" do
    render_inline(TimelineComponent.new(entries: [ entry ], icon: "🍅"))

    assert_selector ".timeline-middle span", text: "🍅"
    assert_no_selector ".timeline-middle span", text: "🌱"
  end

  test "defaults to 🌱 icon" do
    render_inline(TimelineComponent.new(entries: [ entry ]))

    assert_selector ".timeline-middle span", text: "🌱"
  end
end
