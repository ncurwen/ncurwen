import { Controller } from "@hotwired/stimulus"

// Turns the server-rendered "282 days to go" sentence into a live daisyUI countdown.
//
// The digits are painted by daisyUI from a `--value` custom property. We set it here
// rather than in the markup because the app's CSP has no `unsafe-inline` for
// style-src, and a nonce does not cover inline `style` attributes — a server-rendered
// `style="--value:…"` would be blocked and the counter would come up blank. Writing
// through the CSSOM is not subject to CSP, so this is the only place it can happen.
export default class extends Controller {
  static targets = ["sentence", "live", "days", "hours", "minutes", "seconds"]
  static values = {
    startsAt: String,
    maxDays: { type: Number, default: 999 }
  }

  #timer = null
  #onMorph = null

  connect() {
    // Turbo morphs this page in place whenever anyone RSVPs. Morphing diffs
    // attributes, so it reverts the class changes below — re-apply afterwards or the
    // counter silently reverts to the plain sentence on someone else's reply.
    this.#onMorph = () => this.#render()
    document.addEventListener("turbo:morph", this.#onMorph)

    this.#render()
    this.#timer = setInterval(() => this.#render(), 1000)
  }

  disconnect() {
    clearInterval(this.#timer)
    document.removeEventListener("turbo:morph", this.#onMorph)
  }

  #render() {
    if (!this.hasLiveTarget) return

    const remaining = this.#remaining()

    // Out of range in either direction: the sentence is already correct, so just make
    // sure it's the thing on screen.
    if (remaining === null) {
      this.sentenceTarget.classList.remove("sr-only")
      this.liveTarget.classList.add("hidden")
      this.liveTarget.classList.remove("grid")
      return
    }

    this.sentenceTarget.classList.add("sr-only")
    this.liveTarget.classList.remove("hidden")
    this.liveTarget.classList.add("grid")

    for (const [unit, value] of Object.entries(remaining)) {
      this[`${unit}Target`].style.setProperty("--value", value)
    }
  }

  // Null when there's nothing sensible to tick: the party has started, or it's far
  // enough out that daisyUI's `mod(--value, 1000)` would misreport the day count.
  #remaining() {
    const seconds = Math.floor((Date.parse(this.startsAtValue) - Date.now()) / 1000)
    if (seconds <= 0) return null

    const days = Math.floor(seconds / 86400)
    if (days > this.maxDaysValue) return null

    return {
      days,
      hours: Math.floor(seconds / 3600) % 24,
      minutes: Math.floor(seconds / 60) % 60,
      seconds: seconds % 60
    }
  }
}
