import { Controller } from "@hotwired/stimulus"

// Marks the nav link for the current page with aria-current="page", which the
// stylesheet keys the active-link indicator off of.
//
// The nav lives inside a data-turbo-permanent element, so this controller
// connects once and is never torn down across Turbo visits. We therefore can't
// rely on connect() re-running per page; instead we listen for turbo:load
// (fires on initial load and after every Turbo navigation) and re-evaluate.
export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.update = this.update.bind(this)
    document.addEventListener("turbo:load", this.update)
    this.update()
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.update)
  }

  update() {
    const path = window.location.pathname
    this.linkTargets.forEach((link) => {
      const isActive = new URL(link.href).pathname === path
      if (isActive) {
        link.setAttribute("aria-current", "page")
      } else {
        link.removeAttribute("aria-current")
      }
    })
  }
}
