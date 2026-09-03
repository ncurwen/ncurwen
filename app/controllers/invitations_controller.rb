# The wedding invitation, addressed entirely by the token in the URL. There is no
# public entry point: without a valid token there is nothing to see, which keeps
# the guest list off the open web.
class InvitationsController < ApplicationController
  layout "wedding"

  before_action :set_guest

  def index
    @guests = Guest.ordered                # everyone, so guests can see who's coming
    @household = @guest.group_members.ordered  # the rows this token may edit
  end

  def update
    # Scoping through group_members *is* the authorisation rule: a token can only
    # ever address someone in its own household. Anyone else 404s.
    guest = @guest.group_members.find(params[:id])

    # Clicking the answer you already gave shouldn't refresh everyone else's
    # page: `after_commit` fires on every commit, changed or not.
    guest.update!(status: status_param) unless guest.status == status_param

    # Deliberately outside that guard. Re-clicking the answer you already gave
    # writes nothing, but it's exactly the moment a guest is unsure whether the
    # first click registered — so the click always gets a visible response.
    flash[:success] = confirmation_for(guest)
    redirect_to invitations_path(token: @guest.token)
  rescue ActiveRecord::RecordInvalid => e
    Rollbar.error(e)
    flash[:error] = "Something went wrong saving that answer. Please try again."
    redirect_to invitations_path(token: @guest.token)
  end

  # The party as a calendar file. Behind the token like everything else here, so the
  # venue and time don't leak to anyone without an invitation.
  def calendar
    send_data Wedding.to_ics,
              type: "text/calendar; charset=utf-8",
              filename: "party.ics",
              disposition: "attachment"
  end

  private

  # Names the guest: a household can answer for several people, so "you're down
  # as coming" is ambiguous when the button belonged to someone else's card.
  def confirmation_for(guest)
    case guest.status
    when "yes" then "Wonderful — #{guest.name} is down as coming."
    when "no"  then "Thanks for letting us know #{guest.name} can't make it."
    else            "#{guest.name}'s answer has been cleared."
    end
  end

  # An unknown token is indistinguishable from a missing page, by design.
  def set_guest
    @guest = Guest.find_by!(token: params[:token])
  end

  # Allow-listed against the enum so a hand-crafted request can't write junk.
  def status_param
    params.fetch(:status).presence_in(Guest.statuses.keys) ||
      raise(ActionController::BadRequest, "Unknown RSVP status")
  end
end
