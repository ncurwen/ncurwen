import { Controller } from "@hotwired/stimulus"
import confetti from "canvas-confetti"

// The payoff for saying yes.
//
// Attached to the *accept* form only, and fired from its own `turbo:submit-end`, so
// the burst happens in the browser that clicked. Hanging it off the flash message
// instead would also fire it on the broadcast morph that every other open invitation
// receives — everyone in the household would get confetti for someone else's answer.
export default class extends Controller {
  // daisyUI theme tokens are oklch(); canvas-confetti parses hex only, so these are
  // resolved to hex at fire time through a throwaway element (below).
  static TOKENS = ["--color-primary", "--color-accent", "--color-secondary"]

  // Roughly how long the particles stay on screen. Only used to clear the marker.
  static DURATION = 3000

  celebrate(event) {
    if (!event.detail?.success) return
    if (this.#prefersReducedMotion()) return

    const canvas = document.querySelector("[data-wedding-confetti]")
    if (!canvas) return

    const origin = this.#origin()
    const colors = this.#themeColors()
    const fire = this.#confettiFor(canvas)

    // Marks a burst in flight. The canvas is `data-turbo-permanent`, so this survives
    // the morph that follows the redirect — which is the point.
    canvas.dataset.celebrating = "true"
    clearTimeout(canvas.celebrationTimer)
    canvas.celebrationTimer = setTimeout(() => {
      delete canvas.dataset.celebrating
    }, this.constructor.DURATION)

    fire({ particleCount: 70, spread: 55, angle: 60, origin, colors, disableForReducedMotion: true })
    fire({ particleCount: 70, spread: 55, angle: 120, origin, colors, disableForReducedMotion: true })
  }

  // One confetti instance per canvas: `create` registers a resize listener, and a page
  // with several household cards would otherwise stack one per accept button.
  #confettiFor(canvas) {
    canvas.confettiInstance ||= confetti.create(canvas, { resize: true })
    return canvas.confettiInstance
  }

  #prefersReducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  // Burst from the button itself rather than the middle of the screen, so with several
  // household cards on the page it's obvious which person you just answered for.
  //
  // Measures the button, not `this.element`: the controller is on the `button_to`
  // form, which is `display: contents` so the button can be styled directly. Such an
  // element generates no box at all, so its getBoundingClientRect is all zeros — which
  // put every particle in the top-left corner, firing upward, off screen instantly.
  #origin() {
    const button = this.element.querySelector("button") ?? this.element
    const { top, left, width, height } = button.getBoundingClientRect()

    // Detached or still unstyled: centre it rather than firing into the corner.
    if (!width || !height) return { x: 0.5, y: 0.6 }

    return {
      x: (left + width / 2) / window.innerWidth,
      y: (top + height / 2) / window.innerHeight
    }
  }

  // Reads the theme's own tokens, so the confetti matches whichever theme is active.
  //
  // canvas-confetti parses hex only, and our tokens are oklch(). Neither of the
  // obvious conversions works: `getComputedStyle` reports colours in their authored
  // colour space, so it hands back "oklch(0.49 0.12 25)", and reading `fillStyle`
  // back returns the same string rather than converting. Scraping the digits out of
  // it yields a colour nothing like the one asked for — which is how this arrived
  // as an invisible burst of near-black particles.
  //
  // So: paint one pixel and read it. Rasterising is the one step that has to resolve
  // to sRGB bytes, whatever colour space went in.
  #themeColors() {
    const tokens = getComputedStyle(document.documentElement)
    const canvas = document.createElement("canvas")
    canvas.width = canvas.height = 1
    const context = canvas.getContext("2d", { willReadFrequently: true })

    return this.constructor.TOKENS.map((token) => {
      const value = tokens.getPropertyValue(token).trim()
      if (!value) return null

      context.clearRect(0, 0, 1, 1)
      context.fillStyle = value
      context.fillRect(0, 0, 1, 1)

      const [ red, green, blue, alpha ] = context.getImageData(0, 0, 1, 1).data
      if (!alpha) return null

      return `#${[ red, green, blue ].map((c) => c.toString(16).padStart(2, "0")).join("")}`
    }).filter(Boolean)
  }
}
