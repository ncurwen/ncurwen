import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toast", "message"]
  static values  = { text: String }

  timer = null

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
      this.#flash()
    } catch (err) {
      console.error("copy failed", err)
    }
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  #flash() {
    if (!this.hasToastTarget) return
    if (this.hasMessageTarget) this.messageTarget.textContent = `copied: ${this.textValue}!`
    this.toastTarget.classList.remove("hidden")
    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      this.toastTarget.classList.add("hidden")
    }, 1500)
  }
}
