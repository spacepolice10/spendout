import { Controller } from "@hotwired/stimulus"

const DELAY_BEFORE_OBSERVING = 400

export default class extends Controller {
  static targets = [ "paginationLink" ]
  static values = { paginateOnIntersection: { type: Boolean, default: false } }

  connect() {
    if (!this.paginateOnIntersectionValue || !("IntersectionObserver" in window)) return

    this.observer = new IntersectionObserver(this.#intersect, { rootMargin: "300px", threshold: 1 })
  }

  disconnect() {
    this.observer?.disconnect()
    this.observer = undefined
  }

  async paginationLinkTargetConnected(link) {
    await this.#delay(DELAY_BEFORE_OBSERVING)
    this.observer?.observe(link)
  }

  paginationLinkTargetDisconnected(link) {
    this.observer?.unobserve(link)
  }

  #intersect = (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting && entry.intersectionRatio === 1) this.#loadPaginationLink(entry.target)
    })
  }

  #loadPaginationLink(link) {
    if (link.getAttribute("aria-busy") === "true") return

    this.observer?.unobserve(link)
    link.setAttribute("aria-busy", "true")

    const frame = document.createElement("turbo-frame")
    frame.id = link.dataset.paginationFrameParam
    frame.src = link.href
    frame.target = "_top"
    frame.setAttribute("role", "presentation")
    frame.addEventListener("turbo:frame-render", () => {
      this.#mergeSplitDays(frame)
      link.removeAttribute("aria-busy")
    }, { once: true })

    this.element.append(frame)
  }

  #mergeSplitDays(frame) {
    const previousFrame = frame.previousElementSibling
    const incomingDay = frame.querySelector("[data-record-day]")
    const existingDays = previousFrame?.querySelectorAll("[data-record-day]")
    const existingDay = existingDays?.[existingDays.length - 1]
    if (!incomingDay || !existingDay || incomingDay.dataset.date !== existingDay.dataset.date) return

    const existingList = existingDay.querySelector(":scope > main")
    const incomingList = incomingDay.querySelector(":scope > main")
    if (!existingList || !incomingList) return

    existingList.append(...incomingList.children)
    incomingDay.remove()
  }

  #delay(milliseconds) {
    return new Promise((resolve) => setTimeout(resolve, milliseconds))
  }
}
