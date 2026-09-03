# The shared guest list: everyone who's invited, grouped by household, with each
# person's answer visible so guests can see who's coming.
#
# The viewer's own household is marked, since those are the only rows their token
# can change. This renders read-only; the RSVP buttons live in the invitation
# page's own section, so the list stays scannable.
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
    else            "Awaiting reply"
    end
  end

  def status_icon(guest)
    case guest.status
    when "yes" then "check"
    when "no"  then "x"
    else            "circle-dashed"
    end
  end

  def attending_count = guests.count(&:yes?)
end
