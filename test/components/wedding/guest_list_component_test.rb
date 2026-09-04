require "test_helper"
require "view_component/test_helpers"

class WeddingGuestListComponentTest < ViewComponent::TestCase
  def render_list(viewer:)
    render_inline(Wedding::GuestListComponent.new(guests: Guest.ordered.to_a, viewer: viewer))
  end

  test "groups guests into one card per party" do
    render_list(viewer: guests(:alice))

    assert_selector "section.card", count: Guest.distinct.count(:group)
  end

  # The group is a bare number that means nothing to a guest, so no card is
  # titled with it. Restore a heading here and this fails.
  test "gives the cards no heading, so the group number is never shown" do
    render_list(viewer: guests(:alice))

    assert_no_selector "section.card h3"
    assert_no_selector "section.card .card-title"
  end

  test "lists every guest so people can see who's coming" do
    render_list(viewer: guests(:alice))

    Guest.pluck(:name).each { |name| assert_text name }
  end

  test "marks the viewer's own party and no other" do
    render_list(viewer: guests(:alice))

    assert_selector ".wedding-own-household", count: 1
    assert_selector ".wedding-own-household", text: "Alice Attending"
    assert_selector ".badge-primary", text: "You", count: 1
  end

  test "follows the viewer, so a different token marks a different party" do
    render_list(viewer: guests(:carol))

    assert_selector ".wedding-own-household", text: "Carol Elsewhere"
  end

  test "shows each guest's answer" do
    render_list(viewer: guests(:alice))

    assert_selector ".badge-success", text: "Coming"          # alice
    assert_selector ".badge-ghost",   text: "Unknown"  # bob
    assert_selector ".badge-neutral", text: "Can't make it"   # carol
  end

  test "declining is styled neutrally rather than as an error" do
    render_list(viewer: guests(:alice))

    assert_no_selector ".badge-error"
  end

  # Fixtures: alice yes, bob unknown, carol no — across two parties.
  test "leads with the counts rather than a sentence" do
    render_list(viewer: guests(:alice))

    within_stat("Coming") { |stat| assert_equal "1", stat.find(".stat-value").text }
    within_stat("Coming") { |stat| assert_text stat, "of 3 invited" }
    within_stat("Yet to reply") { |stat| assert_equal "1", stat.find(".stat-value").text }
    within_stat("Yet to reply") { |stat| assert_text stat, "1 can’t make it" }
    within_stat("Households") { |stat| assert_equal "2", stat.find(".stat-value").text }
  end

  # A decline is still a reply: the bar is about how much of the roster has answered,
  # not how many are coming.
  test "the progress bar counts replies, not acceptances" do
    render_list(viewer: guests(:alice))

    assert_selector "progress.progress[value='2'][max='3']"
    assert_text "2 of 3 have replied"
  end

  # The pop in wedding.css is an entry animation, and Turbo's morph is not an entry —
  # idiomorph patches the class and text of the node that's already there. It does
  # replace a node whose id changed, so the status has to live in the id or someone
  # else's reply lands in complete silence. These two are the guard on that: delete the
  # ids as clutter and they fail.
  test "keys each badge by its status, so a morph replaces the node instead of patching it" do
    render_list(viewer: guests(:alice))

    assert_selector "#guest-#{guests(:alice).id}-status-yes.wedding-status", text: "Coming"
    assert_selector "#guest-#{guests(:bob).id}-status-unknown.wedding-status", text: "Unknown"
    assert_selector "#guest-#{guests(:carol).id}-status-no.wedding-status", text: "Can't make it"
  end

  test "the badge id follows the answer, so answering changes the key" do
    guests(:bob).update!(status: "yes")
    render_list(viewer: guests(:alice))

    assert_no_selector "#guest-#{guests(:bob).id}-status-unknown"
    assert_selector "#guest-#{guests(:bob).id}-status-yes.wedding-status", text: "Coming"
  end

  test "keys the two counts that move, so they pop when the totals change" do
    render_list(viewer: guests(:alice))

    assert_selector "#wedding-stat-coming-1.stat-value.wedding-status"
    assert_selector "#wedding-stat-awaiting-1.stat-value.wedding-status"
  end

  private

  def within_stat(title, &block)
    stat = page.find(".stat", text: title)
    block.call(stat)
  end
end
