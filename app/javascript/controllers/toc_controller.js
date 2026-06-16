import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.sections = this.linkTargets
      .map(link => document.getElementById(link.dataset.section))
      .filter(Boolean)

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
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.onScroll)
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  update() {
    if (!this.sections.length) return

    const doc       = document.documentElement
    const scrolled  = window.scrollY
    const viewport  = window.innerHeight
    const docHeight = doc.scrollHeight
    const atBottom  = scrolled + viewport >= docHeight - 4
    const threshold = viewport * 0.3

    let activeId
    if (atBottom) {
      activeId = this.sections[this.sections.length - 1].id
    } else {
      for (const section of this.sections) {
        if (section.getBoundingClientRect().top <= threshold) {
          activeId = section.id
        } else {
          break
        }
      }
      activeId ||= this.sections[0].id
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
