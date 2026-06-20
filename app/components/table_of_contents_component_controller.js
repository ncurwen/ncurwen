import { Controller } from "@hotwired/stimulus"

// A section counts as "active" once its top sits within this many pixels of the
// scroller's top edge.
const ACTIVE_THRESHOLD = 120
// Slack (px) for treating the scroller as bottomed-out, absorbing sub-pixel rounding.
const BOTTOM_SLOP = 4
// How long a clicked (pinned) entry stays highlighted before scroll tracking resumes.
const PIN_DURATION = 3000
// Backstop only: the fade-out is driven by the backdrop's `transitionend`; this
// timer just guarantees cleanup when no transition fires (reduced motion, or an
// element detached mid-fade). It need only outlast the CSS transition, not match it.
const FADE_FALLBACK = 700
// The two classes that draw the jumped-to backdrop (see application.tailwind.css).
const ACTIVE_CLASSES = ["toc-active-section", "toc-active-section--fading"]

export default class extends Controller {
  static targets = ["link"]

  connect() {
    // Page content scrolls inside #page-body, not the window (see the layout).
    // Fall back to the document element if it's ever absent.
    this.scroller = document.getElementById("page-body")
    this.scrollTarget = this.scroller || window
    this.collectSections()

    this.onScroll = () => {
      if (this.frame) return
      this.frame = requestAnimationFrame(() => {
        this.frame = null
        this.update()
      })
    }
    // Mirror typewriter_controller's convention: own the Turbo lifecycle here
    // rather than wiring it through the template. before-cache strips the pin so
    // the cached snapshot is clean; morph rebuilds against the patched DOM.
    this.onBeforeCache = () => this.deactivate()
    this.onMorph = () => this.refresh()

    this.scrollTarget.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("resize", this.onScroll, { passive: true })
    document.addEventListener("turbo:before-cache", this.onBeforeCache)
    document.addEventListener("turbo:morph", this.onMorph)

    this.update()

    // Honour a deep link (/page#section): native fragment scrolling targets the
    // window, which can't reach the #page-body scroller, so drive it ourselves.
    const id = decodeURIComponent(location.hash.slice(1))
    if (id && this.sections.some(s => s.id === id)) this.jumpTo(id, { smooth: false })
  }

  disconnect() {
    this.scrollTarget.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onScroll)
    document.removeEventListener("turbo:before-cache", this.onBeforeCache)
    document.removeEventListener("turbo:morph", this.onMorph)
    if (this.frame) cancelAnimationFrame(this.frame)
    clearTimeout(this.pinTimer)
    this.pinnedId = null
    this.clearHighlight()
  }

  // turbo:before-cache. Turbo snapshots the live DOM for its back/forward cache
  // here, so strip the pin highlight and active styling first — otherwise a
  // restored snapshot flashes a stale active entry for a frame before connect()
  // recomputes it from scroll position.
  deactivate() {
    clearTimeout(this.pinTimer)
    this.pinnedId = null
    this.clearHighlight()
    this.setActive(null)
  }

  // turbo:morph. A morph patches the page in place, so this controller persists
  // and connect() never re-runs — leaving this.sections pointing at replaced
  // nodes plus a possibly-pending pin. Rebuild from the new DOM. Clicks are
  // delegated Stimulus actions (auto-rebound) and the turbo listeners are on
  // document (they survive), so only the scroller binding is refreshed, and only
  // because the morph may have swapped #page-body out from under it.
  refresh() {
    clearTimeout(this.pinTimer)
    this.pinnedId = null
    this.clearHighlight()

    this.scrollTarget.removeEventListener("scroll", this.onScroll)
    this.scroller = document.getElementById("page-body")
    this.scrollTarget = this.scroller || window
    this.scrollTarget.addEventListener("scroll", this.onScroll, { passive: true })

    this.collectSections()
    this.update()
  }

  // Links appear twice (desktop sidebar + mobile dropdown), so dedupe to keep
  // this.sections in monotonic document order for the threshold scan in update().
  collectSections() {
    this.sections = [...new Set(this.linkTargets.map(link => link.dataset.section))]
      .map(id => document.getElementById(id))
      .filter(Boolean)
  }

  // Delegated click handler (data-action in the template). Drive the jump
  // ourselves: a native in-page fragment navigation makes Turbo snapshot the page
  // (firing turbo:before-cache), and deactivate() would strip the pin the instant
  // we set it. preventDefault keeps the click from navigating; jumpTo scrolls and
  // syncs the hash by hand instead.
  onLinkClick(e) {
    e.preventDefault()
    this.jumpTo(e.currentTarget.dataset.section, { smooth: true })
  }

  // Pin, highlight, and scroll to a section. Shared by clicks and deep links.
  jumpTo(id, { smooth = true } = {}) {
    const el = document.getElementById(id)
    if (!el) return
    this.pinnedId = id
    this.setActive(id)
    this.highlightSection(el)
    el.scrollIntoView({ behavior: smooth ? "smooth" : "auto", block: "start" })
    history.replaceState(history.state, "", `#${id}`)
    document.activeElement?.blur()
    this.schedulePinRelease()
  }

  // A clicked entry stays pinned for PIN_DURATION regardless of scrolling, then
  // fades out and hands control back to scroll-based detection. A fresh click resets it.
  schedulePinRelease() {
    clearTimeout(this.pinTimer)
    this.pinTimer = setTimeout(() => {
      this.pinnedId = null
      this.fadeOutHighlight()
      this.update()
    }, PIN_DURATION)
  }

  // Hide/show a section's entry (e.g. "garden-2024") when the page hides that
  // section. The link appears twice (desktop aside + mobile dropdown), so toggle
  // each one's <li> wrapper.
  setSectionHidden(id, hidden) {
    this.linkTargets.forEach((link) => {
      if (link.dataset.section === id) link.closest("li").hidden = hidden
    })
  }

  highlightSection(el) {
    this.clearHighlight()
    el.classList.remove("toc-active-section--fading")
    el.classList.add("toc-active-section")
    this.highlightedEl = el
  }

  // Ease the backdrop out, then strip the classes once it has gone. highlightedEl
  // keeps pointing at the fading element so a subsequent click can still clear it
  // (clearHighlight). transitionend is the source of truth; FADE_FALLBACK only
  // covers the cases where no transition fires.
  fadeOutHighlight() {
    const el = this.highlightedEl
    if (!el) return

    // Reduced motion disables the transition (no transitionend would fire); the
    // backdrop is already gone, so just strip the classes now.
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.clearHighlight()
      return
    }

    el.classList.add("toc-active-section--fading")
    this.fadeStrip = () => {
      if (this.highlightedEl === el) this.clearHighlight()
    }
    el.addEventListener("transitionend", this.fadeStrip, { once: true })
    this.fadeTimer = setTimeout(this.fadeStrip, FADE_FALLBACK)
  }

  clearHighlight() {
    clearTimeout(this.fadeTimer)
    const el = this.highlightedEl
    if (!el) return
    if (this.fadeStrip) el.removeEventListener("transitionend", this.fadeStrip)
    this.fadeStrip = null
    el.classList.remove(...ACTIVE_CLASSES)
    this.highlightedEl = null
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
