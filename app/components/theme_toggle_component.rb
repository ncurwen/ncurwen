class ThemeToggleComponent < ApplicationComponent
  # Source of truth for the daisyUI theme keys. The layout renders the initial
  # <html data-theme> from the `light_mode` cookie using these, and
  # theme_toggle_component_controller.js mirrors them when toggling live.
  LIGHT_THEME_NAME = "ncurwen-light"
  DARK_THEME_NAME  = "ncurwen-dark"

  def light_mode?
    helpers.cookies[:light_mode] == "true"
  end
end
