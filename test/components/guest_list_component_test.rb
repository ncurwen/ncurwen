require "test_helper"
require "view_component/test_helpers"

class GuestListComponentTest < ViewComponent::TestCase
  def render_list(viewer:)
    render_inline(GuestListComponent.new(guests: Guest.ordered.to_a, viewer: viewer))
  end

  test "groups guests into one card per household" do
    render_list(viewer: guests(:alice))

    assert_selector "section.card", count: Guest.distinct.count(:group)
    assert_text "The Attending Household"
    assert_text "The Elsewhere Household"
  end

  test "lists every guest so people can see who's coming" do
    render_list(viewer: guests(:alice))

    Guest.pluck(:name).each { |name| assert_text name }
  end

  test "marks the viewer's own household and no other" do
    render_list(viewer: guests(:alice))

    assert_selector ".wedding-own-household", count: 1
    assert_selector ".wedding-own-household", text: "The Attending Household"
    assert_selector ".badge-primary", text: "You", count: 1
  end

  test "follows the viewer, so a different token marks a different household" do
    render_list(viewer: guests(:carol))

    assert_selector ".wedding-own-household", text: "The Elsewhere Household"
  end

  test "shows each guest's answer" do
    render_list(viewer: guests(:alice))

    assert_selector ".badge-success", text: "Coming"          # alice
    assert_selector ".badge-ghost",   text: "Awaiting reply"  # bob
    assert_selector ".badge-neutral", text: "Can't make it"   # carol
  end

  test "declining is styled neutrally rather than as an error" do
    render_list(viewer: guests(:alice))

    assert_no_selector ".badge-error"
  end

  test "counts only the guests who have accepted" do
    render_list(viewer: guests(:alice))

    assert_text "1 of 3 guests have said yes"
  end
end
