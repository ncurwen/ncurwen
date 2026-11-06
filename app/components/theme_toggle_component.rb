# Light/dark toggle, shared by the main site and the wedding invitation.
#
# The two differ in one meaningful way. The main site's cookie has two states
# and always renders an explicit data-theme, so the server knows which icon is
# right. The invitation has three — light, dark, and *absent*, meaning "follow
# the device" — and in that third state the server cannot know what the guest is
# seeing, so the Stimulus controller settles it on connect.
class ThemeToggleComponent < ApplicationComponent
  LIGHT_THEME_NAME = "ncurwen-light"
  DARK_THEME_NAME  = "ncurwen-dark"

  # Defaults reproduce the main site exactly, so its call site stays bare.
  def initialize(light: LIGHT_THEME_NAME,
                 dark: DARK_THEME_NAME,
                 cookie: "light_mode",
                 light_value: "true",
                 dark_value: "false",
                 default_dark: true)
    @light = light
    @dark = dark
    @cookie = cookie
    @light_value = light_value
    @dark_value = dark_value
    @default_dark = default_dark
  end

  # Checked means dark. With no cookie the caller decides: the main site has
  # always opened dark, while the invitation renders light and lets the
  # controller correct it from the device preference.
  def dark?
    case helpers.cookies[cookie]
    when light_value then false
    when dark_value  then true
    else                  default_dark
    end
  end

  private

  attr_reader :light, :dark, :cookie, :light_value, :dark_value, :default_dark
end
