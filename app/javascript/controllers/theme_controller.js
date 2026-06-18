import { Controller } from "@hotwired/stimulus"

const LIGHT = "ncurwen-light"
const DARK  = "ncurwen-dark"
const KEY   = "ncurwen-theme"

// The active theme is set on <html> before first paint by the inline script in
// the layout <head> (kept in sync with the constants above). This controller
// only owns the toggle interaction; on connect it just reflects the already
// applied theme onto the toggle, rather than re-deriving it here.
export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    this.#syncToggle()
  }

  toggle() {
    const next = document.documentElement.dataset.theme === DARK ? LIGHT : DARK
    document.documentElement.dataset.theme = next
    localStorage.setItem(KEY, next)
    this.#syncToggle()
  }

  #syncToggle() {
    if (this.hasToggleTarget) {
      this.toggleTarget.checked = document.documentElement.dataset.theme === DARK
    }
  }
}
