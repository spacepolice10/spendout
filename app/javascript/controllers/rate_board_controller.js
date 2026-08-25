import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["base", "row", "rate"]
  static values = {
    snapshots: Array,
    interval: { type: Number, default: 0 }
  }

  connect() {
    this.index = 0
    this.paused = false
    this.reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)")

    this.element.addEventListener("mouseenter", this.pause)
    this.element.addEventListener("mouseleave", this.resume)
    this.element.addEventListener("focusin", this.pause)
    this.element.addEventListener("focusout", this.resume)
    document.addEventListener("visibilitychange", this.visibilityChanged)

    this.#render(this.snapshotsValue[0])
    this.#observeEntrance()
    this.#schedule()
  }

  disconnect() {
    this.#cancel(true)
    this.entranceObserver?.disconnect()
    window.clearTimeout(this.entranceTimer)
    this.element.removeEventListener("mouseenter", this.pause)
    this.element.removeEventListener("mouseleave", this.resume)
    this.element.removeEventListener("focusin", this.pause)
    this.element.removeEventListener("focusout", this.resume)
    document.removeEventListener("visibilitychange", this.visibilityChanged)
  }

  intervalValueChanged() {
    if (!this.reduceMotion || this.paused) return

    this.#schedule()
  }

  pause = () => {
    this.paused = true
    this.#cancel()
  }

  resume = () => {
    window.queueMicrotask(() => {
      this.paused = this.element.matches(":hover") || this.element.contains(document.activeElement) || document.hidden
      this.#schedule()
    })
  }

  visibilityChanged = () => {
    document.hidden ? this.pause() : this.resume()
  }

  #advance = () => {
    if (this.paused || this.reduceMotion.matches || this.intervalValue <= 0 || this.snapshotsValue.length < 2) return

    this.index = (this.index + 1) % this.snapshotsValue.length
    this.element.toggleAttribute("data-rate-board-changing", true)

    this.changeTimer = window.setTimeout(() => {
      this.#render(this.snapshotsValue[this.index])
      this.element.removeAttribute("data-rate-board-changing")
      this.#schedule()
    }, 160)
  }

  #render(snapshot) {
    if (!snapshot) return

    this.currentSnapshot = snapshot
    if (this.hasBaseTarget) this.baseTarget.textContent = `1 ${snapshot.base}`

    snapshot.rows.forEach((row, index) => {
      const tableRow = this.rowTargets[index]
      const output = this.rateTargets[index]
      if (!tableRow || !output) return

      tableRow.querySelector("[data-rate-code]").textContent = row.code
      tableRow.querySelector("[data-rate-name]").textContent = row.name
      output.textContent = row.rate
      output.replaceChildren(this.#accessibleValue(row.rate), this.#segmentValue(row.rate))
    })
  }

  #observeEntrance() {
    if (this.reduceMotion.matches || !("IntersectionObserver" in window)) return

    this.entranceObserver = new IntersectionObserver(this.#enter, { threshold: 0.35 })
    this.entranceObserver.observe(this.element)
  }

  #enter = (entries) => {
    if (!entries.some((entry) => entry.isIntersecting && entry.intersectionRatio >= 0.35)) return

    this.entranceObserver.disconnect()
    this.element.toggleAttribute("data-rate-board-entering", true)

    this.currentSnapshot.rows.forEach((row, index) => {
      const visual = this.rateTargets[index]?.querySelector("[data-segment-display]")
      visual?.replaceWith(this.#segmentValue(this.#nudgedValue(row.rate)))
    })

    this.entranceTimer = window.setTimeout(() => {
      this.currentSnapshot.rows.forEach((row, index) => {
        const visual = this.rateTargets[index]?.querySelector("[data-segment-display]")
        visual?.replaceWith(this.#segmentValue(row.rate))
      })
      this.element.removeAttribute("data-rate-board-entering")
    }, 240)
  }

  #nudgedValue(value) {
    const digitIndex = value.search(/\d(?=\D*$)/)
    if (digitIndex < 0) return value

    const nextDigit = (Number.parseInt(value[digitIndex], 10) + 1) % 10
    return `${value.slice(0, digitIndex)}${nextDigit}${value.slice(digitIndex + 1)}`
  }

  #accessibleValue(value) {
    const span = document.createElement("span")
    span.dataset.rateText = ""
    span.textContent = value
    return span
  }

  #segmentValue(value) {
    const display = document.createElement("span")
    display.dataset.segmentDisplay = ""
    display.setAttribute("aria-hidden", "true")

    for (const character of value) {
      const digit = document.createElement("span")
      digit.dataset.segmentDigit = character

      if (/\d/.test(character)) {
        for (const segment of "abcdefg") {
          const part = document.createElement("i")
          part.dataset.segment = segment
          digit.append(part)
        }
      } else if (![".", ","].includes(character)) {
        digit.textContent = character
      }

      display.append(digit)
    }

    return display
  }

  #schedule() {
    this.#cancel()
    if (this.paused || this.reduceMotion.matches || this.intervalValue <= 0 || this.snapshotsValue.length < 2) return

    this.timer = window.setTimeout(this.#advance, this.intervalValue)
  }

  #cancel(includeChange = false) {
    window.clearTimeout(this.timer)
    if (includeChange) window.clearTimeout(this.changeTimer)
  }
}
