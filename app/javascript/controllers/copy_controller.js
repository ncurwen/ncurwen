import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "toast"]

  async copy() {
    const text = this.sourceTarget.textContent.trim()
    try {
      await navigator.clipboard.writeText(text)
      this.flash()
    } catch (err) {
      console.error("copy failed", err)
    }
  }

  flash() {
    if (!this.hasToastTarget) return
    this.toastTarget.classList.remove("hidden")
    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      this.toastTarget.classList.add("hidden")
    }, 1500)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
