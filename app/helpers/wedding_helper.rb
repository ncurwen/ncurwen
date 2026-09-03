# Everything the wedding invitation needs from a helper, in one file so the whole
# feature can be lifted out again once the party is over.
#
# The rest of the invitation is isolated the same way — its components live under the
# `Wedding::` namespace so they sit in directories of their own. Whole directories and
# files to delete:
#
#   app/helpers/wedding_helper.rb          (this file)
#   app/models/wedding.rb                  event date, venue, .ics
#   app/models/guest.rb                    + db/migrate/*_create_guests.rb
#   app/controllers/invitations_controller.rb
#   app/views/invitations/
#   app/views/layouts/wedding.html.erb
#   app/components/wedding/                Countdown, GuestList, RsvpControls
#   app/assets/stylesheets/wedding.css
#   lib/tasks/wedding.rake
#   test/components/wedding/
#   test/system/wedding_*.rb
#   test/models/{wedding,guest}_test.rb
#   test/controllers/invitations_controller_test.rb
#
# Then the edits, none of which are whole-file deletions:
#
#   * application.tailwind.css: the `wedding` and `wedding-dark` theme blocks, the
#     `wedding-*` keyframes, and the `@import "./wedding.css"`. `default: true`
#     currently sits on the `wedding` theme — move it back to `ncurwen-light`, or
#     every page without a data-theme falls through to a theme that no longer exists.
#   * config/routes.rb: the `resources :invitations` block.
#   * db/seeds.rb: the wedding roster.
#   * public/robots.txt: `Disallow: /wedding/`.
#   * package.json: the canvas-confetti dependency.
#   * app/components/index.js: regenerate with
#     `bin/rails view_component:stimulus_manifest:update`.
#   * test/controllers/pages_controller_test.rb: the theme tripwire test, which only
#     exists because of the `default: true` above.
#   * test/components/theme_toggle_component_test.rb: the `wedding_toggle` cases.
module WeddingHelper
  # The invitation's theme names, and the cookie values a guest's explicit choice is
  # stored under. Returns nil when they haven't chosen, which makes the layout render
  # *no* data-theme — the state daisyUI's prefersdark rule (`:root:not([data-theme])`)
  # needs in order to follow the device.
  WEDDING_THEMES = { "light" => "wedding", "dark" => "wedding-dark" }.freeze

  def wedding_theme(choice) = WEDDING_THEMES[choice]

  # The token holder's own answer, restated in the hero so a returning guest can see
  # where they stand without scrolling to the RSVP section. Third status deliberately
  # `badge-warning`: it's the one that still wants something from them.
  #
  # Speaks only for the reader, not their household — the RSVP cards below are where
  # per-person answers live.
  RSVP_CHIPS = {
    "yes" => [ "badge-success", "check", "You're coming" ],
    "no" => [ "badge-neutral badge-outline", "x", "You've let us know" ],
    "unknown" => [ "badge-warning badge-soft", "circle-dashed", "We still need your answer" ]
  }.freeze

  def rsvp_status_chip(guest)
    classes, icon, label = RSVP_CHIPS.fetch(guest.status)

    tag.p(class: "badge badge-lg gap-2 #{classes}") do
      safe_join([ lucide_icon(icon, class: "h-4 w-4"), label ])
    end
  end

  # An answered guest is being offered a second thought, not asked the question again.
  def rsvp_cta_label(guest) = guest.unknown? ? "RSVP" : "Change your answer"

  # The wedding-only half of the ComponentHelper `*_tag` convention. Same thin
  # forwarders, kept here rather than in component_helper.rb so they leave with
  # everything else. The invitation also renders `theme_toggle_tag` and `flash_tag`,
  # which stay put — the main site uses those too.
  def countdown_tag(...) = render Wedding::CountdownComponent.new(...)
  def guest_list_tag(...) = render Wedding::GuestListComponent.new(...)
  def rsvp_controls_tag(...) = render Wedding::RsvpControlsComponent.new(...)
end
