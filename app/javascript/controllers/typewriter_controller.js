import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text"]
  static values  = { phrases: Array, typeMs: { type: Number, default: 70 }, eraseMs: { type: Number, default: 35 }, holdMs: { type: Number, default: 1500 } }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    if (!this.phrasesValue?.length) return
    this.index = 0
    this.stopped = false
    this.cycle()
  }

  disconnect() {
    this.stopped = true
    clearTimeout(this.timer)
  }

  async cycle() {
    if (this.stopped) return
    const phrase = this.phrasesValue[this.index]
    await this.type(phrase)
    if (this.stopped) return
    await this.wait(this.holdMsValue)
    if (this.stopped) return
    await this.erase()
    this.index = (this.index + 1) % this.phrasesValue.length
    this.cycle()
  }

  type(phrase) {
    return new Promise((resolve) => {
      let i = 0
      this.textTarget.textContent = ""
      const tick = () => {
        if (i >= phrase.length) return resolve()
        this.textTarget.textContent += phrase.charAt(i++)
        this.timer = setTimeout(tick, this.typeMsValue)
      }
      tick()
    })
  }

  erase() {
    return new Promise((resolve) => {
      const tick = () => {
        const current = this.textTarget.textContent
        if (!current) return resolve()
        this.textTarget.textContent = current.slice(0, -1)
        this.timer = setTimeout(tick, this.eraseMsValue)
      }
      tick()
    })
  }

  wait(ms) {
    return new Promise((resolve) => { this.timer = setTimeout(resolve, ms) })
  }
}
