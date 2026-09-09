import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { scrollLeft: Number }

  connect() {
    this.savedLeft = this.#read() ?? (this.hasScrollLeftValue ? this.scrollLeftValue : null)
    this.ready = false
    this.restore()
    requestAnimationFrame(() => {
      this.restore()
      this.ready = true
    })

    this.events = new AbortController()
    window.addEventListener("pagehide", this.persist, { signal: this.events.signal })
  }

  disconnect() {
    this.ready = true
    this.persist()
    this.events.abort()
  }

  persist = () => {
    if (!this.ready) return

    const left = this.element.scrollLeft
    this.scrollLeftValue = left
    this.#write(left)
  }

  restore() {
    if (this.savedLeft == null) return

    this.element.scrollLeft = this.savedLeft
  }

  get #key() {
    return `lens-carousel:${location.pathname}`
  }

  #read() {
    try {
      const value = sessionStorage.getItem(this.#key)
      if (value == null || value === "") return null

      const left = Number(value)
      return Number.isFinite(left) ? left : null
    } catch {
      return null
    }
  }

  #write(left) {
    try {
      sessionStorage.setItem(this.#key, String(left))
    } catch {}
  }
}
