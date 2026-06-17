import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.sections = this.linkTargets
      .map(link => document.getElementById(link.dataset.section))
      .filter(Boolean)

    this.onLinkClick = (e) => {
      this.pinnedId = e.currentTarget.dataset.section
      this.setActive(this.pinnedId)
    }
    this.linkTargets.forEach(link => link.addEventListener("click", this.onLinkClick))

    this.clearPin = () => { this.pinnedId = null }
    this.onKeydown = (e) => {
      if (["PageDown","PageUp","ArrowDown","ArrowUp","End","Home"," "].includes(e.key)) {
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
    window.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("resize", this.onScroll, { passive: true })
    this.update()
  }

  disconnect() {
    this.linkTargets.forEach(link => link.removeEventListener("click", this.onLinkClick))
    window.removeEventListener("wheel", this.clearPin)
    window.removeEventListener("touchmove", this.clearPin)
    window.removeEventListener("keydown", this.onKeydown)
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onScroll)
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  update() {
    if (!this.sections.length) return
    if (this.pinnedId) {
      this.setActive(this.pinnedId)
      return
    }

    const doc       = document.documentElement
    const scrolled  = window.scrollY
    const viewport  = window.innerHeight
    const docHeight = doc.scrollHeight
    const atBottom  = scrolled + viewport >= docHeight - 4
    const threshold = 120

    let activeId
    for (const section of this.sections) {
      if (section.getBoundingClientRect().top <= threshold) {
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
          if (top > threshold && top <= viewport) {
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
