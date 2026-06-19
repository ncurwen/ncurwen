import { Controller } from "@hotwired/stimulus"

// Light/dark theme toggle. The cookie is the single source of truth: the server
// renders both <html data-theme> and this checkbox's checked state from it, so
// the theme and icon are correct at first paint with no flash. This controller
// only handles the live click — flipping the theme and writing the cookie back
// so the choice survives a reload. Keys mirror ThemeToggleComponent's constants.
const LIGHT = "ncurwen-light"
const DARK  = "ncurwen-dark"

export default class extends Controller {
  toggle() {
    const isDark = this.element.checked
    document.documentElement.dataset.theme = isDark ? DARK : LIGHT
    document.cookie = `light_mode=${!isDark}; path=/; max-age=31536000; SameSite=Lax`
  }
}
