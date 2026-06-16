import { Controller } from "@hotwired/stimulus"

const LIGHT = "ncurwen-light"
const DARK  = "ncurwen-dark"
const KEY   = "ncurwen-theme"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    const stored = localStorage.getItem(KEY)
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches
    const theme = stored || (prefersDark ? DARK : LIGHT)
    this.apply(theme)
  }

  toggle() {
    const next = document.documentElement.dataset.theme === DARK ? LIGHT : DARK
    this.apply(next)
    localStorage.setItem(KEY, next)
  }

  apply(theme) {
    document.documentElement.dataset.theme = theme
    if (this.hasToggleTarget) {
      this.toggleTarget.checked = theme === DARK
    }
  }
}
