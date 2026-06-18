require "test_helper"
require "view_component/test_helpers"

class WorkHistoryComponentTest < ViewComponent::TestCase
  def position(company: "Acme Corp", period: "2018–2024", location: "Remote", summary: "Built things.", roles: nil)
    {
      company: company,
      period: period,
      location: location,
      summary: summary,
      roles: roles || [ role ]
    }
  end

  def role(title: "Senior Engineer", period: "2020–2024", bullets: [ "Shipped a feature.", "Fixed a bug." ])
    { title: title, period: period, bullets: bullets }
  end

  test "renders nothing when positions are empty" do
    render_inline(WorkHistoryComponent.new(positions: []))

    assert_no_selector "article.timeline-entry"
  end

  test "renders one timeline entry per position" do
    render_inline(WorkHistoryComponent.new(positions: [ position, position, position ]))

    assert_selector "article.timeline-entry", count: 3
  end

  test "uses a parameterized company anchor as the article id" do
    render_inline(WorkHistoryComponent.new(positions: [ position(company: "Big R&D Shop") ]))

    assert_selector "article#work-big-r-d-shop"
  end

  test "renders an h4 per role and an li per bullet" do
    roles = [ role(bullets: [ "a", "b" ]), role(bullets: [ "c" ]) ]
    render_inline(WorkHistoryComponent.new(positions: [ position(roles: roles) ]))

    assert_selector "h4", count: 2
    assert_selector "ul > li", count: 3
  end

  test "renders location and summary only when present" do
    render_inline(WorkHistoryComponent.new(positions: [
      position(location: "Remote", summary: "Built things.")
    ]))
    assert_text "Remote"
    assert_text "Built things."

    render_inline(WorkHistoryComponent.new(positions: [
      position(location: nil, summary: nil)
    ]))
    refute_text "Remote"
    refute_text "Built things."
  end

  test "omits the bullets list when a role has no bullets" do
    render_inline(WorkHistoryComponent.new(positions: [
      position(roles: [ role(bullets: nil) ])
    ]))

    assert_no_selector "ul"
  end
end
