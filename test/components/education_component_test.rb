require "test_helper"
require "view_component/test_helpers"

class EducationComponentTest < ViewComponent::TestCase
  def school(school: "State University", period: "2010–2014", credential: "BSc Computer Science", location: "Anytown", honours: [ "First class", "Dean's list" ])
    {
      school: school,
      period: period,
      credential: credential,
      location: location,
      honours: honours
    }
  end

  test "renders nothing when schools are empty" do
    render_inline(EducationComponent.new(schools: []))

    assert_no_selector "article.card"
  end

  test "renders one card per school with its credential" do
    render_inline(EducationComponent.new(schools: [ school, school ]))

    assert_selector "article.card", count: 2
    assert_text "BSc Computer Science"
  end

  test "renders honours badges only when present" do
    render_inline(EducationComponent.new(schools: [
      school(honours: [ "First class", "Dean's list" ])
    ]))
    assert_selector "span.badge", count: 2

    render_inline(EducationComponent.new(schools: [ school(honours: nil) ]))
    assert_no_selector "span.badge"
  end

  test "renders location only when present" do
    render_inline(EducationComponent.new(schools: [ school(location: nil) ]))

    refute_text "Anytown"
  end
end
