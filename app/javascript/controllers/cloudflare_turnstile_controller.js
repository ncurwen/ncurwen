import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    window.addEventListener("turbo:before-render", this.#cleanup)
  }

  disconnect() {
    window.removeEventListener("turbo:before-render", this.#cleanup)
  }

  #cleanup = () => {
    const widget = this.element.querySelector(".cf-turnstile")
    if (widget && window.turnstile) {
      window.turnstile.remove(widget)
    }
  }
}
