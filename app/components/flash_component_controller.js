import Notification from '@stimulus-components/notification'

export default class extends Notification {
  static targets = ["progress"]
  static values = {
    delay: { type: Number, default: 6000 },
    autoDismiss: { type: Boolean, default: true }
  }

  #progressInterval = null

  disconnect() {
    clearInterval(this.#progressInterval)
    super.disconnect()
  }

  show() {
    this.enter()

    if (this.autoDismissValue === true) {
      this.timeout = setTimeout(this.hide, this.delayValue)
      if (this.hasProgressTarget) {
        this.#progressInterval = setInterval(() => {
          this.progressTarget.value += 1
          if (this.progressTarget.value >= this.progressTarget.max) clearInterval(this.#progressInterval)
        }, 20)
      }
    }
  }
}
