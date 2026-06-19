import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "image", "caption", "counter", "dot", "chip", "chapter", "tile", "toc"]
  static values  = { images: Array }

  connect() {
    this.index = 0
    this.activeYear = "all"
    this.activeMonths = new Set()   // empty = all months
    this.preloaded = new Set()
    this.applyFilters()
  }

  // ── Filtering ──────────────────────────────────────────────────────────────
  // Year row: single select.
  filter({ params: { year } }) {
    this.activeYear = String(year)
    this.applyFilters()
  }

  // Month row: multi select. "all" clears the set back to every month.
  toggleMonth({ params: { month } }) {
    if (month === "all") {
      this.activeMonths.clear()
    } else {
      const m = String(month)
      this.activeMonths.has(m) ? this.activeMonths.delete(m) : this.activeMonths.add(m)
    }
    this.applyFilters()
  }

  monthActive(m) {
    return this.activeMonths.size === 0 || this.activeMonths.has(String(m))
  }

  applyFilters() {
    // Month hides individual tiles…
    this.tileTargets.forEach((tile) => {
      tile.hidden = !this.monthActive(tile.dataset.month)
    })

    // …then a chapter shows only if its year matches AND it still has a visible tile.
    this.chapterTargets.forEach((chapter) => {
      const yearOk = this.activeYear === "all" || chapter.dataset.year === this.activeYear
      const hasVisible = chapter.querySelectorAll(
        "[data-photo-gallery-component-target~='tile']:not([hidden])"
      ).length > 0
      chapter.hidden = !(yearOk && hasVisible)
    })

    // Pressed state for both rows.
    const monthAll = this.activeMonths.size === 0
    this.chipTargets.forEach((chip) => {
      const y  = chip.dataset.photoGalleryComponentYearParam
      const mo = chip.dataset.photoGalleryComponentMonthParam
      let pressed
      if (y  !== undefined)  pressed = y === this.activeYear
      else if (mo === "all") pressed = monthAll
      else                   pressed = this.activeMonths.has(String(mo))
      chip.setAttribute("aria-pressed", pressed)
      chip.classList.toggle("btn-primary", pressed)
    })

    // The jump-to sidebar still helps while filtering by month (all years on
    // screen); only a single-year filter collapses it to one chapter.
    if (this.hasTocTarget) {
      this.tocTarget.hidden = this.activeYear !== "all"
    }

    this.refreshActiveIndices()
  }

  // Global indices currently visible, in display order.
  refreshActiveIndices() {
    this.activeIndices = this.imagesValue.reduce((acc, img, i) => {
      const yearOk = this.activeYear === "all" || img.year === this.activeYear
      if (yearOk && this.monthActive(img.month)) acc.push(i)
      return acc
    }, [])
  }

  // ── Lightbox ───────────────────────────────────────────────────────────────
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
    return this.imagesValue.map((_, i) => i)
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
    const entry = this.imagesValue[i]
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
    const entry = this.imagesValue[this.index]
    if (!entry) return

    this.imageTarget.src = entry.url
    this.imageTarget.alt = entry.basename
    this.captionTarget.textContent = entry.date || entry.basename
    this.dotTarget.dataset.season = entry.season

    const set = this.currentSet()
    const current = String(set.indexOf(this.index) + 1).padStart(2, "0")
    const total = String(set.length).padStart(2, "0")
    this.counterTarget.textContent = `${current} / ${total}`

    this.preloadNeighbors(set)
  }
}
