require "test_helper"
require "turbo/broadcastable/test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper
  include ActiveJob::TestHelper

  # --- access -------------------------------------------------------------

  test "an unknown token is indistinguishable from a missing page" do
    get invitations_path(token: "nosuchtokennosuchtokennn")

    assert_response :not_found
  end

  test "there is no way to reach the invitation without a token" do
    get "/wedding"
    assert_response :not_found

    get "/wedding/"
    assert_response :not_found
  end

  # Deliberately asserts on structure and the guest's own data rather than the
  # page's wording, which is still being written.
  test "a valid token renders the invitation, addressed to that guest" do
    get invitations_path(token: guests(:alice).token)

    assert_response :success
    assert_select "h1"
    assert_select "#rsvp"
    assert_select "body", text: /Alice Attending/
  end

  test "the invitation is kept out of search results" do
    get invitations_path(token: guests(:alice).token)

    assert_select "meta[name=robots][content*=noindex]", count: 1
  end

  # --- the page -----------------------------------------------------------

  test "uses the wedding layout, not the main site's" do
    get invitations_path(token: guests(:alice).token)

    # Structural, not textual: the invitation's wording is still being written.
    assert_select "header#primary-nav", count: 0   # main site nav
    assert_select "footer#site-footer", count: 0   # main site footer
    assert_select "footer"                         # the invitation's own
  end

  # The absent attribute is the point, not an oversight: daisyUI's prefersdark
  # rule is `:root:not([data-theme])`, so rendering any value here — even an
  # empty one — would stop the invitation following the guest's device.
  test "renders no theme attribute until the guest picks one" do
    get invitations_path(token: guests(:alice).token)

    assert_select "html:not([data-theme])"
  end

  test "honours an explicit theme choice in either direction" do
    cookies[:wedding_theme] = "dark"
    get invitations_path(token: guests(:alice).token)
    assert_select "html[data-theme=wedding-dark]"

    cookies[:wedding_theme] = "light"
    get invitations_path(token: guests(:alice).token)
    assert_select "html[data-theme=wedding]"
  end

  test "ignores an unrecognised theme cookie rather than emitting it" do
    cookies[:wedding_theme] = "ncurwen-dark"
    get invitations_path(token: guests(:alice).token)

    assert_select "html:not([data-theme])"
  end

  test "subscribes to the shared stream so the list updates live" do
    get invitations_path(token: guests(:alice).token)

    assert_select "turbo-cable-stream-source"
    assert_select "meta[name='turbo-refresh-method'][content=morph]"
    assert_select "meta[name='turbo-refresh-scroll'][content=preserve]"
  end

  test "lists every guest, not just the viewer's household" do
    get invitations_path(token: guests(:alice).token)

    Guest.pluck(:name).each { |name| assert_select "body", text: /#{Regexp.escape(name)}/ }
  end

  test "offers RSVP controls for the whole household but nobody else" do
    get invitations_path(token: guests(:alice).token)

    # Alice and Bob share a household; Carol does not.
    assert_select "form[action=?]", invitation_path(token: guests(:alice).token, id: guests(:alice).id)
    assert_select "form[action=?]", invitation_path(token: guests(:alice).token, id: guests(:bob).id)
    assert_select "form[action=?]", invitation_path(token: guests(:alice).token, id: guests(:carol).id), count: 0
  end

  # --- rsvp ---------------------------------------------------------------

  test "records an RSVP and returns to the invitation" do
    patch invitation_path(token: guests(:bob).token, id: guests(:bob).id), params: { status: "yes" }

    assert_redirected_to invitations_path(token: guests(:bob).token)
    assert_predicate guests(:bob).reload, :yes?
  end

  test "confirms the answer, naming the guest it was given for" do
    patch invitation_path(token: guests(:alice).token, id: guests(:bob).id), params: { status: "yes" }

    assert_match(/Bob Attending/, flash[:success])
  end

  # The confirmation is deliberately outside the no-op guard below: writing
  # nothing is exactly when a guest is unsure whether their first click landed.
  test "confirms a re-submitted answer even though nothing was written" do
    assert_no_turbo_stream_broadcasts "guest_list" do
      perform_enqueued_jobs do
        patch invitation_path(token: guests(:alice).token, id: guests(:alice).id), params: { status: "yes" }
      end
    end

    assert_match(/Alice Attending/, flash[:success])
  end

  test "a token can answer for someone else in its own household" do
    patch invitation_path(token: guests(:alice).token, id: guests(:bob).id), params: { status: "no" }

    assert_response :redirect
    assert_predicate guests(:bob).reload, :no?
  end

  test "clearing an answer returns the guest to unknown" do
    patch invitation_path(token: guests(:alice).token, id: guests(:alice).id), params: { status: "unknown" }

    assert_predicate guests(:alice).reload, :unknown?
  end

  # The authorisation rule. Scoping the lookup through the household is the only
  # thing standing between a guest and everyone else's RSVP.
  test "a token cannot answer for a guest in another household" do
    patch invitation_path(token: guests(:alice).token, id: guests(:carol).id), params: { status: "yes" }

    assert_response :not_found
    assert_predicate guests(:carol).reload, :no?, "Carol's RSVP should be untouched"
  end

  test "rejects a status outside the enum" do
    patch invitation_path(token: guests(:bob).token, id: guests(:bob).id), params: { status: "maybe" }

    assert_response :bad_request
    assert_predicate guests(:bob).reload, :unknown?
  end

  test "an RSVP refreshes every other open invitation" do
    streams = capture_turbo_stream_broadcasts "guest_list" do
      perform_enqueued_jobs do
        patch invitation_path(token: guests(:bob).token, id: guests(:bob).id), params: { status: "yes" }
      end
    end

    assert_equal "refresh", streams.sole["action"]
  end

  test "re-submitting the same answer doesn't refresh everyone for nothing" do
    assert_no_turbo_stream_broadcasts "guest_list" do
      perform_enqueued_jobs do
        patch invitation_path(token: guests(:alice).token, id: guests(:alice).id), params: { status: "yes" }
      end
    end
  end

  test "serves the party as a downloadable calendar file" do
    get calendar_invitations_path(token: guests(:alice).token)

    assert_response :success
    assert_match "text/calendar", response.media_type
    assert_match(/attachment; filename="party\.ics"/, response.headers["Content-Disposition"])
    assert_match "BEGIN:VEVENT", response.body
  end

  # The venue and time are behind the token like everything else here.
  test "the calendar file needs a valid token" do
    get calendar_invitations_path(token: "nobody")

    assert_response :not_found
  end
end
