# The shared guest list: everyone who's invited, grouped by household, with each
# person's answer visible so guests can see who's coming.
#
# The viewer's own household is marked, since those are the only rows their token
# can change. This renders read-only; the RSVP buttons live in the invitation
# page's own section, so the list stays scannable.
module Wedding
  class GuestListComponent < ApplicationComponent
    def initialize(guests:, viewer:)
      @guests = guests
      @viewer = viewer
    end

    private

    attr_reader :guests, :viewer

    def households = guests.group_by(&:group)

    def own_household?(group) = group == viewer.group

    # `no` gets neutral rather than `badge-error` — someone being unable to come
    # isn't an error, and a wall of red would read badly on an invitation.
    def status_badge_class(guest)
      case guest.status
      when "yes" then "badge badge-success badge-sm gap-1"
      when "no"  then "badge badge-neutral badge-outline badge-sm gap-1"
      else            "badge badge-ghost badge-sm gap-1"
      end
    end

    def status_label(guest)
      case guest.status
      when "yes" then "Coming"
      when "no"  then "Can't make it"
      else            "Unknown"
      end
    end

    def status_icon(guest)
      case guest.status
      when "yes" then "check"
      when "no"  then "x"
      else            "circle-dashed"
      end
    end

    # The badge's animation is an entry animation, and morphing never re-enters an
    # element — idiomorph patches the class and text in place, so the pop never fires.
    # It does refuse to morph an element whose id changed, removing the old node and
    # inserting a fresh one, which is a real entry. So the id carries the status: the
    # id is the key, and changing the key means "replace me". Drop it and the badge
    # swaps colour and wording in silence.
    def status_dom_id(guest) = "guest-#{guest.id}-status-#{guest.status}"

    def attending_count = guests.count(&:yes?)

    def declined_count = guests.count(&:no?)

    # Everyone who hasn't answered either way yet.
    def awaiting_count = guests.size - attending_count - declined_count

    def household_count = households.size

    # Drives the progress bar: replies in, not yeses in. A decline is still a reply,
    # and the bar is about how much of the roster we've heard from.
    def replied_count = attending_count + declined_count

    # `max` on the bar rather than a computed percentage — <progress> takes both, and
    # passing the raw counts keeps the markup readable and avoids a divide-by-zero on
    # an empty roster.
    def reply_progress_label
      return "No replies yet." if replied_count.zero?

      "#{replied_count} of #{guests.size} have replied."
    end
  end
end
