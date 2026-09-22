# One invited person. The token in their invitation URL identifies them, and
# unlocks RSVP for everyone sharing their `group`, so a single link can answer
# for the whole party. `group` is an opaque number rather than a name: linking
# the party is the only job it has, and it is never rendered to a guest.
#
# The roster is maintained in db/seeds.rb; `status` is guest-owned and is never
# written by seeding. See lib/tasks/wedding.rake for the invitation links.
class Guest < ApplicationRecord
  TOKEN_LENGTH = 6

  # Generated on create, so nothing has to be minted by hand. Uniqueness is
  # enforced by the unique index rather than a validation's read-then-write.
  # Hand-rolled rather than has_secure_token: that macro refuses anything
  # under 24 characters, which is too long to type on an invitation.
  before_create { self.token ||= SecureRandom.base58(TOKEN_LENGTH) }

  # String-backed so the stored value reads as itself in the database.
  enum :status, { unknown: "unknown", yes: "yes", no: "no" }, validate: true

  validates :name, :group, presence: true

  # Turbo 8: any change refreshes every open invitation, which morphs the guest
  # list in place. Turbo stamps the broadcast with the originating request id,
  # so the guest who clicked ignores their own echo and just follows the redirect.
  # The lambda form matters: a bare symbol would be `send`-ed to the record as a
  # method name (it's meant for associations, e.g. `broadcasts_refreshes_to :board`).
  # Every guest shares one stream, so the name is a constant.
  broadcasts_refreshes_to ->(_guest) { :guest_list }

  scope :ordered, -> { order(:group, :name) }

  # The rows this guest's token is allowed to RSVP for — the authorisation
  # boundary the invitations controller scopes its lookup through.
  def group_members = self.class.where(group: group)
end
