import { Controller } from "@hotwired/stimulus"

// The full-screen lightbox: opening a frame, ←/→ navigation, and neighbour
// preloading. It owns no gallery data of its own — the sibling filter controller
// holds the image list and the active (filtered) set, which this reads through an
// outlet so there's a single source of truth.
export default class extends Controller {
  static targets = ["dialog", "image", "caption", "counter", "dot", "fitLabel", "fitToggle"]
  static outlets = ["photo-gallery-filter-component"]

  connect() {
    this.index = 0
    this.preloaded = new Set()
    this.fill = false
  }

  // Tap the frame (or the footer flag) to switch between fitting the whole photo
  // on screen and filling the screen with it — the win on a phone, where a
  // landscape frame otherwise sits letterboxed in a thin strip. The choice is
  // sticky across ←/→ so you can browse a year at one zoom.
  toggleFit() {
    this.fill = !this.fill
    this.imageTarget.classList.toggle("object-cover", this.fill)
    this.imageTarget.classList.toggle("object-contain", !this.fill)
    this.fitLabelTarget.textContent = this.fill ? "fill" : "fit"
    this.fitToggleTarget.setAttribute("aria-pressed", String(this.fill))
  }

  // The frame isn't focusable, so a mousedown on it would otherwise begin a
  // text-selection drag on the page behind the dialog and pull focus off the
  // nav buttons; suppressing the default keeps focus put and stops the stray
  // selection at its source, while the click (→ toggleFit) still fires.
  preventSelect(event) {
    event.preventDefault()
  }

  // Borrowed from the filter controller (single source of truth).
  get images() {
    return this.photoGalleryFilterComponentOutlet.imagesValue
  }

  get activeIndices() {
    return this.photoGalleryFilterComponentOutlet.activeIndices
  }

  open({ params: { index } }) {
    if (Number.isNaN(index)) return
    if (!this.hasPhotoGalleryFilterComponentOutlet) return
    this.index = index
    this.render()
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  next() {
    this.step(1)
  }

  prev() {
    this.step(-1)
  }

  // The set the lightbox navigates: the active filter when the current image
  // belongs to it, otherwise the full gallery (e.g. opening the hero while a
  // single year is filtered).
  currentSet() {
    if (this.activeIndices.includes(this.index)) return this.activeIndices
    return this.images.map((_, i) => i)
  }

  // Move within the current set, wrapping at its bounds.
  step(delta) {
    const set = this.currentSet()
    const pos = set.indexOf(this.index)
    this.index = set[(pos + delta + set.length) % set.length]
    this.render()
  }

  // Fetch a full image into the browser cache without inserting it. Each url
  // is fetched at most once.
  warm(i) {
    const entry = this.images[i]
    if (!entry || this.preloaded.has(i)) return
    this.preloaded.add(i)
    const img = new Image()
    img.src = entry.url
  }

  // Pre-fetch the images on either side of the current one so left/right
  // navigation is instant.
  preloadNeighbors(set) {
    const pos = set.indexOf(this.index)
    if (pos === -1) return
    this.warm(set[(pos + 1) % set.length])
    this.warm(set[(pos - 1 + set.length) % set.length])
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
    const entry = this.images[this.index]
    if (!entry) return

    this.imageTarget.src = entry.url
    this.imageTarget.alt = entry.basename
    this.captionTarget.textContent = entry.date || entry.basename
    this.dotTarget.dataset.season = entry.season
    this.dotTarget.dataset.tip = entry.season
      ? entry.season.charAt(0).toUpperCase() + entry.season.slice(1)
      : ""

    const set = this.currentSet()
    const current = String(set.indexOf(this.index) + 1).padStart(2, "0")
    const total = String(set.length).padStart(2, "0")
    this.counterTarget.textContent = `${current} / ${total}`

    this.preloadNeighbors(set)
  }
}
