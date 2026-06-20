import { Controller } from "@hotwired/stimulus"

// Sentinel year/month value meaning "no filter" (every year / every month).
const ALL = "all"

// Tooltip shown on a selected chip, whose click now clears its filter.
const CLEAR_TIP = "Clear filter"

// Owns the gallery's filtering: the year/month chips, their live counts, and the
// visibility of tiles and year chapters. It also keeps `activeIndices` — the
// global image indices currently on screen, in display order — which the sibling
// lightbox controller reads through an outlet. Holds the only copy of the gallery
// JSON (`images` value); the lightbox borrows it rather than duplicating it.
export default class extends Controller {
  static targets = ["chip", "chapter", "tile", "toc"]
  static outlets = ["table-of-contents-component"]
  static values  = { images: Array }

  connect() {
    this.activeYear = ALL
    this.activeMonths = new Set()   // empty = all months
    this.applyFilters()
  }

  // Re-sync once the jump-to sidebar is available, regardless of connect order.
  tableOfContentsComponentOutletConnected() {
    this.applyFilters()
  }

  // ── Filtering ──────────────────────────────────────────────────────────────
  // Year row: single select, toggle to clear. Re-clicking the active year (or the
  // "all" chip) resets to ALL; any other year selects it. Mirrors toggleMonth.
  filter({ params: { year } }) {
    const y = String(year)
    this.activeYear = (y === ALL || y === this.activeYear) ? ALL : y
    this.applyFilters()
  }

  // Month row: multi select. "all" clears the set back to every month.
  toggleMonth({ params: { month } }) {
    if (month === ALL) {
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
    const monthN = this.monthCounts()   // { month: n } within the active year
    this.pruneMonths(monthN)            // forget selected months absent this year
    const yearN = this.yearCounts()     // { year: n } within the active months (post-prune)

    // Month hides individual tiles…
    this.tileTargets.forEach((tile) => {
      tile.hidden = !this.monthActive(tile.dataset.month)
    })

    // …then each chapter: visible iff its year matches AND it still has a tile. Its
    // frame count stays the server-rendered year total (it doesn't track the month
    // filter, matching the month-range text beside it); only its TOC entry follows
    // the visible subset.
    let visibleYears = 0
    this.chapterTargets.forEach((chapter) => {
      const yearOk = this.activeYear === ALL || chapter.dataset.year === this.activeYear
      const visibleTiles = chapter.querySelectorAll(
        "[data-photo-gallery-filter-component-target~='tile']:not([hidden])"
      ).length
      const visible = yearOk && visibleTiles > 0
      chapter.hidden = !visible
      if (visible) visibleYears++

      if (this.hasTableOfContentsComponentOutlet) {
        this.tableOfContentsComponentOutlet.setSectionHidden(`garden-${chapter.dataset.year}`, !visible)
      }
    })

    this.syncChips(monthN, yearN)

    // Hide the year-jump sidebar whenever the filters leave a single year on
    // screen — whether that came from a year chip or from month selection.
    if (this.hasTocTarget) this.tocTarget.hidden = visibleYears <= 1

    this.refreshActiveIndices()
  }

  // Frames per month within the active year (all years when "all").
  monthCounts() {
    const counts = {}
    this.imagesValue.forEach((img) => {
      if (this.activeYear !== ALL && img.year !== this.activeYear) return
      if (img.month == null) return
      counts[img.month] = (counts[img.month] || 0) + 1
    })
    return counts
  }

  // Frames per year within the active month selection (all years when "all").
  yearCounts() {
    const counts = {}
    this.imagesValue.forEach((img) => {
      if (!this.monthActive(img.month)) return
      if (img.year == null) return
      counts[img.year] = (counts[img.year] || 0) + 1
    })
    return counts
  }

  // A selected month with no frames in the active year can't show — its chip is
  // about to disappear, so drop it to avoid a blank gallery.
  pruneMonths(counts) {
    for (const m of this.activeMonths) if (!(m in counts)) this.activeMonths.delete(m)
  }

  syncChips(monthN, yearN) {
    const monthAll   = this.activeMonths.size === 0
    const monthTotal = Object.values(monthN).reduce((a, b) => a + b, 0)  // active year, all months
    const yearTotal  = Object.values(yearN).reduce((a, b) => a + b, 0)   // selected months, all years

    this.chipTargets.forEach((chip) => {
      const y  = chip.dataset.photoGalleryFilterComponentYearParam
      const mo = chip.dataset.photoGalleryFilterComponentMonthParam

      if (y !== undefined) {                 // year row — single select
        if (y === ALL) {
          this.press(chip, this.activeYear === ALL)
          this.setCount(chip, yearTotal)
        } else {
          const n = yearN[y] || 0
          this.setChipHidden(chip, n === 0 && y !== this.activeYear)   // never hide the active year
          this.setCount(chip, n)
          this.press(chip, y === this.activeYear)
        }
        return
      }

      if (mo === ALL) {                      // month row — multi select
        this.press(chip, monthAll)
        this.setCount(chip, monthTotal)
      } else {
        const n = monthN[mo] || 0
        this.setChipHidden(chip, n === 0)
        this.setCount(chip, n)
        this.press(chip, this.activeMonths.has(mo))
      }
    })
  }

  // Chips may be wrapped in a daisyUI .tooltip div; hide that wrapper so a hidden
  // chip leaves no empty gap in the flex row. Unwrapped chips fall back to self.
  setChipHidden(chip, hidden) {
    (chip.closest(".tooltip") || chip).hidden = hidden
  }

  press(chip, on) {
    chip.setAttribute("aria-pressed", String(on))
    chip.classList.toggle("btn-primary", on)
    this.setTip(chip, on)
  }

  // Selected chip → its click clears the filter, so its tooltip says so.
  // Unselected chip → restore the server-rendered contents list ("Months:…"/"Years:…").
  setTip(chip, on) {
    const tip = chip.closest(".tooltip")
    if (!tip) return                                    // "all" chips have no tooltip wrapper
    if (tip.dataset.tipDefault === undefined) tip.dataset.tipDefault = tip.dataset.tip ?? ""
    tip.dataset.tip = on ? CLEAR_TIP : tip.dataset.tipDefault
  }

  setCount(chip, n) {
    const el = chip.querySelector("[data-chip-count]")
    if (el) el.textContent = n
  }

  // Global indices currently visible, in display order. Read by the lightbox.
  refreshActiveIndices() {
    this.activeIndices = this.imagesValue.reduce((acc, img, i) => {
      const yearOk = this.activeYear === ALL || img.year === this.activeYear
      if (yearOk && this.monthActive(img.month)) acc.push(i)
      return acc
    }, [])
  }
}
