# The accept / decline buttons for one guest.
#
# Each is a real PATCH form via `button_to`, so this needs no JavaScript at all:
# Turbo submits it, follows the redirect, and morphs the result. The guest's
# current answer is rendered as the pressed button rather than a separate label.
class RsvpControlsComponent < ApplicationComponent
  # The acting guest's token, which is what the invitation URL is addressed by.
  def initialize(guest:, token:)
    @guest = guest
    @token = token
  end

  private

  attr_reader :guest, :token

  def rsvp_path = helpers.invitation_path(token: token, id: guest.id)

  # The standing answer, stated in words on every visit. The filled-vs-outlined
  # button carries the same information, but a week after answering that's far
  # too quiet a signal to recognise as "you already did this".
  #
  # Second person, deliberately: GuestListComponent says "Coming" *about*
  # someone, this speaks *to* the person holding the token. Same three statuses,
  # different voice, so the wording isn't shared between them.
  def standing_answer
    case guest.status
    when "yes" then "Down as coming."
    when "no"  then "Down as unable to come."
    else            "No answer yet."
    end
  end

  # Matches GuestListComponent#status_icon so the card and the list agree.
  def standing_answer_icon
    case guest.status
    when "yes" then "check"
    when "no"  then "x"
    else            "circle-dashed"
    end
  end

  # `btn-primary` is spent here, on the one action the page is asking for.
  # Everything else stays quieter so the ask reads clearly.
  def button_class(status)
    # Always stacked and full width. These sit in a fixed 320px card now, and
    # "Regretfully declines" wraps to two lines at anything narrower than about
    # 200px — so there is no width at which side by side is worth a breakpoint.
    base = "btn btn-sm sm:btn-md w-full gap-2 normal-case"
    return "#{base} btn-primary" if status == "yes" && guest.yes?
    return "#{base} btn-neutral" if status == "no" && guest.no?

    "#{base} #{status == 'yes' ? 'btn-outline btn-primary' : 'btn-outline'}"
  end
end
