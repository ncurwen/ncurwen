import { Controller } from "@hotwired/stimulus"

// The full-screen lightbox: opening a frame, ←/→ navigation, and neighbour
// preloading. It owns no gallery data of its own — the sibling filter controller
// holds the image list and the active (filtered) set, which this reads through an
// outlet so there's a single source of truth.

// Held while a new photo decodes. An <img> keeps painting its previous bitmap
// until the replacement is ready, so without hiding it, reopening the lightbox
// on a different photo shows the last one first. The frame wears daisyUI's
// skeleton in the meantime — the same shimmer the grid tiles use, so a photo
// arriving reads the same way in both places.
const PENDING = "opacity-0"
const LOADING = "skeleton"

export default class extends Controller {
  static targets = ["dialog", "frame", "source", "image", "caption", "counter", "dot", "fitLabel", "fitToggle"]
  static outlets = ["photo-gallery-filter-component"]

  connect() {
    this.index = 0
    this.preloaded = new Set()
    this.fill = false
    this.renderToken = 0
    this.imageTarget.addEventListener("load", () => this.rememberChoice(), { once: true })
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

  // Which of the two candidates this browser actually takes. A bare
  // `new Image()` bypasses <picture> negotiation, so warming the WebP blindly
  // would fetch bytes a non-WebP browser never uses — and then the 1.1 MB
  // original on top. Read the browser's own choice off currentSrc after the
  // first frame paints; WebP is the right guess until then.
  get warmKey() {
    return this.chosenKey || "large"
  }

  // Full-screen frames are served at near-source quality, so each one is a few
  // hundred KB and warming both neighbours spends roughly triple that before
  // the viewer has asked for either. That's a good trade on a fast connection
  // and a bad one on a metered or slow link, so skip it when the browser says
  // so. Only Chromium reports this; everywhere else preloading stays on, which
  // is the old behaviour.
  get shouldPreload() {
    const net = navigator.connection
    if (!net) return true
    if (net.saveData) return false
    return !/(^|-)2g$/.test(net.effectiveType || "")
  }

  // Hold the frame blank until the new photo is actually decodable, so the
  // dialog never shows the previous one. decode() settles in a microtask for
  // anything already cached — the warmed neighbours you reach with ←/→ — so
  // stepping through a year stays instant and doesn't blink.
  //
  // The token guards against fast arrow presses: an in-flight decode() for a
  // photo that has already been navigated past must not reveal the frame, and
  // it rejects with AbortError when its src is replaced, which is not an error
  // worth surfacing.
  revealWhenDecoded() {
    const token = ++this.renderToken
    const img = this.imageTarget

    img.classList.add(PENDING)
    this.frameTarget.classList.add(LOADING)

    img.decode().catch(() => {}).then(() => {
      if (token !== this.renderToken) return

      img.classList.remove(PENDING)
      this.frameTarget.classList.remove(LOADING)
    })
  }

  setDimensions({ width, height }) {
    if (width && height) {
      this.imageTarget.width = width
      this.imageTarget.height = height
    } else {
      this.imageTarget.removeAttribute("width")
      this.imageTarget.removeAttribute("height")
    }
  }

  rememberChoice() {
    const src = this.imageTarget.currentSrc
    if (src) this.chosenKey = src.endsWith(".webp") ? "large" : "original"
  }

  // Fetch a full image into the browser cache without inserting it. Each url
  // is fetched at most once, at low priority so it can't compete with the
  // frame the viewer is actually looking at.
  warm(i) {
    const entry = this.images[i]
    if (!entry || this.preloaded.has(i)) return
    this.preloaded.add(i)
    const img = new Image()
    img.fetchPriority = "low"
    img.src = entry[this.warmKey]
  }

  // Pre-fetch the images on either side of the current one so left/right
  // navigation is instant — worth a few hundred KB each only when the
  // connection can spare it.
  preloadNeighbors(set) {
    if (!this.shouldPreload) return

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

    // Order matters: assigning src re-runs <picture> source selection from
    // scratch, so it picks up the srcset set just above. Setting src alone
    // would leave the stale <source> winning and show the previous photo.
    this.sourceTarget.srcset = entry.large || ""
    this.imageTarget.src = entry.original
    this.imageTarget.alt = entry.basename
    // Dimensions are only known once the derivatives manifest has been built;
    // assigning undefined would coerce to 0 and stamp width="0" on the frame.
    this.setDimensions(entry)
    this.revealWhenDecoded()
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
