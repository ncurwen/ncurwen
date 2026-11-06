import { Controller } from "@hotwired/stimulus"

// Light/dark theme toggle, shared by the main site and the wedding invitation.
//
// The theme names and cookie arrive as values so one controller serves both.
// Defaults reproduce the main site's original behaviour exactly: the cookie is
// the source of truth there, the server renders <html data-theme> and this
// checkbox from it, and the theme is correct at first paint with no flash.
//
// The invitation adds a third state. When a guest hasn't chosen, it renders no
// data-theme at all so daisyUI's prefersdark rule (:root:not([data-theme])) can
// follow the device — which means the *server* can't know which icon to show.
// connect() settles that on the client.
export default class extends Controller {
  static values = {
    light: { type: String, default: "ncurwen-light" },
    dark: { type: String, default: "ncurwen-dark" },
    cookie: { type: String, default: "light_mode" },
    lightCookie: { type: String, default: "true" },
    darkCookie: { type: String, default: "false" }
  }

  // Match the icon to what's actually on screen. An explicit data-theme is
  // authoritative; without one the device preference is what's being rendered.
  connect() {
    const theme = document.documentElement.dataset.theme

    this.element.checked = theme
      ? theme === this.darkValue
      : window.matchMedia("(prefers-color-scheme: dark)").matches
  }

  toggle() {
    const isDark = this.element.checked

    document.documentElement.dataset.theme = isDark ? this.darkValue : this.lightValue
    document.cookie = `${this.cookieValue}=${isDark ? this.darkCookieValue : this.lightCookieValue}; path=/; max-age=31536000; SameSite=Lax`
  }
}
