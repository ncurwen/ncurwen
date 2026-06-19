import { Controller } from "@hotwired/stimulus"

// A section counts as "active" once its top sits within this many pixels of the
// scroller's top edge.
const ACTIVE_THRESHOLD = 120
// Slack (px) for treating the scroller as bottomed-out, absorbing sub-pixel rounding.
const BOTTOM_SLOP = 4
// Keys that scroll the page — pressing any of them releases a pinned (clicked) entry.
const SCROLL_KEYS = ["PageDown", "PageUp", "ArrowDown", "ArrowUp", "End", "Home", " "]

export default class extends Controller {
  static targets = ["link"]

  connect() {
    // Page content scrolls inside #page-body, not the window (see the layout).
    // Fall back to the document element if it's ever absent.
    this.scroller = document.getElementById("page-body")
    this.scrollTarget = this.scroller || window

    // Links appear twice (desktop sidebar + mobile dropdown), so dedupe to keep
    // this.sections in monotonic document order for the threshold scan in update().
    this.sections = [...new Set(this.linkTargets.map(link => link.dataset.section))]
      .map(id => document.getElementById(id))
      .filter(Boolean)

    this.onLinkClick = (e) => {
      this.pinnedId = e.currentTarget.dataset.section
      this.setActive(this.pinnedId)
      this.highlightSection(this.pinnedId)
      // Content scrolls inside #page-body, so native fragment scrolling doesn't
      // reach it on mobile. Scroll explicitly, then close the daisyUI dropdown.
      document.getElementById(this.pinnedId)?.scrollIntoView({ behavior: "smooth", block: "start" })
      document.activeElement?.blur()
    }
    this.linkTargets.forEach(link => link.addEventListener("click", this.onLinkClick))

    this.clearPin = () => {
      this.pinnedId = null
      this.clearHighlight()
    }
    this.onKeydown = (e) => {
      if (SCROLL_KEYS.includes(e.key)) {
        this.clearPin()
      }
    }
    window.addEventListener("wheel", this.clearPin, { passive: true })
    window.addEventListener("touchmove", this.clearPin, { passive: true })
    window.addEventListener("keydown", this.onKeydown)

    this.onScroll = () => {
      if (this.frame) return
      this.frame = requestAnimationFrame(() => {
        this.frame = null
        this.update()
      })
    }
    this.scrollTarget.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("resize", this.onScroll, { passive: true })
    this.update()
  }

  disconnect() {
    this.linkTargets.forEach(link => link.removeEventListener("click", this.onLinkClick))
    window.removeEventListener("wheel", this.clearPin)
    window.removeEventListener("touchmove", this.clearPin)
    window.removeEventListener("keydown", this.onKeydown)
    this.scrollTarget.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onScroll)
    if (this.frame) cancelAnimationFrame(this.frame)
    this.clearHighlight()
  }

  // Hide/show a section's entry (e.g. "garden-2024") when the page hides that
  // section. The link appears twice (desktop aside + mobile dropdown), so toggle
  // each one's <li> wrapper.
  setSectionHidden(id, hidden) {
    this.linkTargets.forEach((link) => {
      if (link.dataset.section === id) link.closest("li").hidden = hidden
    })
  }

  highlightSection(id) {
    this.clearHighlight()
    const el = document.getElementById(id)
    if (el) {
      el.classList.add("toc-active-section")
      this.highlightedEl = el
    }
  }

  clearHighlight() {
    if (this.highlightedEl) {
      this.highlightedEl.classList.remove("toc-active-section")
      this.highlightedEl = null
    }
  }

  update() {
    if (!this.sections.length) return
    if (this.pinnedId) {
      this.setActive(this.pinnedId)
      return
    }

    const metrics   = this.scroller || document.documentElement
    const scrolled  = metrics.scrollTop
    const viewport  = metrics.clientHeight
    const docHeight = metrics.scrollHeight
    const atBottom  = scrolled + viewport >= docHeight - BOTTOM_SLOP

    let activeId
    for (const section of this.sections) {
      if (section.getBoundingClientRect().top <= ACTIVE_THRESHOLD) {
        activeId = section.id
      } else {
        break
      }
    }
    activeId ||= this.sections[0].id

    // On tall viewports, the page may bottom out before a late section's top can reach
    // the threshold. In that case promote the next section that's actually visible.
    if (atBottom) {
      const active = this.sections.find(s => s.id === activeId)
      if (active && active.getBoundingClientRect().top < 0) {
        for (const s of this.sections) {
          const top = s.getBoundingClientRect().top
          if (top > ACTIVE_THRESHOLD && top <= viewport) {
            activeId = s.id
            break
          }
        }
      }
    }

    this.setActive(activeId)
  }

  setActive(id) {
    if (id === this.activeId) return
    this.activeId = id
    this.linkTargets.forEach(link => {
      const match = link.dataset.section === id
      link.classList.toggle("text-primary", match)
      link.classList.toggle("font-bold", match)
      link.classList.toggle("text-base-content/60", !match)
    })
  }
}
