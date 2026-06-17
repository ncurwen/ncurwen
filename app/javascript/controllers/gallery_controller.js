import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "image", "caption", "counter"]
  static values  = { images: Array }

  connect() {
    this.index = 0
  }

  open({ params: { index } }) {
    if (Number.isNaN(index)) return
    this.index = index
    this.render()
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  next() {
    this.index = (this.index + 1) % this.imagesValue.length
    this.render()
  }

  prev() {
    const len = this.imagesValue.length
    this.index = (this.index - 1 + len) % len
    this.render()
  }

  keydown(event) {
    if (event.key === "ArrowRight") {
      event.preventDefault()
      this.next()
    } else if (event.key === "ArrowLeft") {
      event.preventDefault()
      this.prev()
    }
  }

  render() {
    const entry = this.imagesValue[this.index]
    if (!entry) return
    this.imageTarget.src = entry.url
    this.imageTarget.alt = entry.basename
    this.captionTarget.textContent = entry.date || entry.basename
    const total = String(this.imagesValue.length).padStart(2, "0")
    const current = String(this.index + 1).padStart(2, "0")
    this.counterTarget.textContent = `${current} / ${total}`
  }
}
