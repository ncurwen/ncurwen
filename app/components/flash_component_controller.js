import Notification from '@stimulus-components/notification'

export default class extends Notification {
  static targets = ["timer"]
  static values = {
    delay: { type: Number, default: 6000 },
    autoDismiss: { type: Boolean, default: true }
  }

  #timer = null

  disconnect() {
    this.#stopTimer()
    super.disconnect()
  }

  show() {
    this.enter()

    if (this.autoDismissValue !== true) return

    this.timeout = setTimeout(this.hide, this.delayValue)
    this.#startTimer()
  }

  // Hand the whole countdown to the compositor in one call.
  //
  // This used to tick a <progress> element from a timer. Two problems, one
  // visible and one not: counting ticks drifted (an interval fires *at least*
  // its delay apart, never exactly), so the bar sat around 92% when the toast
  // left; and daisyUI transitions that element's inline-size, so every write
  // restarted a layout animation. Six seconds of per-frame style, layout and
  // paint on the main thread — which is where the confetti burst that fires
  // with a success toast is also drawing, so the two fought for the frame.
  //
  // A scale animation is composited: no main-thread work after this line, and
  // it lands exactly full at delayValue because that *is* its duration.
  #startTimer() {
    if (!this.hasTimerTarget) return
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    // Animates `scale`, not `transform`, to match the resting scale-x-0 class:
    // Tailwind v4 compiles that to the standalone `scale` property, which
    // *multiplies* with `transform` rather than being replaced by it — so a
    // transform animation here stayed pinned at zero width.
    this.#timer = this.timerTarget.animate(
      [{ scale: "0 1" }, { scale: "1 1" }],
      { duration: this.delayValue, easing: "linear", fill: "forwards" }
    )
  }

  #stopTimer() {
    this.#timer?.cancel()
    this.#timer = null
  }
}
