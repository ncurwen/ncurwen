require "test_helper"
require "turbo/broadcastable/test_helper"

class GuestTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper
  include ActiveJob::TestHelper

  test "generates a token on create so none has to be assigned by hand" do
    guest = Guest.create!(name: "New Guest", group: 99)

    assert_predicate guest.token, :present?
    assert_equal 6, guest.token.length
  end

  test "keeps the token stable across later saves so invitation links keep working" do
    guest = Guest.create!(name: "New Guest", group: 99)
    original = guest.token

    guest.update!(name: "Renamed Guest")

    assert_equal original, guest.reload.token
  end

  test "issues a distinct token to each guest" do
    tokens = 3.times.map { Guest.create!(name: "Guest #{_1}", group: 99).token }

    assert_equal tokens.uniq.size, tokens.size
  end

  test "starts every guest at unknown" do
    assert_predicate Guest.create!(name: "New Guest", group: 99), :unknown?
  end

  test "accepts only the three RSVP states" do
    guest = guests(:bob)

    assert_equal %w[unknown yes no], Guest.statuses.keys

    guest.update!(status: "yes")
    assert_predicate guest.reload, :yes?

    guest.status = "maybe"
    assert_not guest.valid?
    assert_includes guest.errors[:status], "is not included in the list"
  end

  test "requires a name and a group" do
    guest = Guest.new

    assert_not guest.valid?
    assert_includes guest.errors[:name], "can't be blank"
    assert_includes guest.errors[:group], "can't be blank"
  end

  test "group_members returns everyone in the same group, including self" do
    assert_equal [ "Alice Attending", "Bob Attending" ],
                 guests(:alice).group_members.ordered.map(&:name)
  end

  test "group_members excludes other groups" do
    assert_not_includes guests(:alice).group_members, guests(:carol)
  end

  test "ordered sorts by group then name" do
    assert_equal [ "Alice Attending", "Bob Attending", "Carol Elsewhere" ],
                 Guest.ordered.map(&:name)
  end

  # This is what makes the guest list live: one shared stream that every open
  # invitation subscribes to. The broadcast goes out via `_later`, so the job has
  # to actually run for anything to reach Action Cable.
  test "broadcasts a refresh to the shared guest list stream when a guest replies" do
    streams = capture_turbo_stream_broadcasts "guest_list" do
      perform_enqueued_jobs { guests(:bob).update!(status: "yes") }
    end

    assert_equal 1, streams.size
    assert_equal "refresh", streams.sole["action"]
  end
end
