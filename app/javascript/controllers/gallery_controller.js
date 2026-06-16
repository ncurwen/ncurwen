import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "image", "caption", "counter"]
  static values  = { images: Array, currentIndex: { type: Number, default: 0 } }

  open(event) {
    const index = parseInt(event.currentTarget.dataset.galleryIndexParam, 10)
    if (Number.isNaN(index)) return
    this.currentIndexValue = index
    this.render()
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  next() {
    this.currentIndexValue = (this.currentIndexValue + 1) % this.imagesValue.length
    this.render()
  }

  prev() {
    const len = this.imagesValue.length
    this.currentIndexValue = (this.currentIndexValue - 1 + len) % len
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
    const entry = this.imagesValue[this.currentIndexValue]
    if (!entry) return
    this.imageTarget.src = entry.url
    this.imageTarget.alt = entry.basename
    this.captionTarget.textContent = entry.date || entry.basename
    const total = String(this.imagesValue.length).padStart(2, "0")
    const current = String(this.currentIndexValue + 1).padStart(2, "0")
    this.counterTarget.textContent = `${current} / ${total}`
  }
}
