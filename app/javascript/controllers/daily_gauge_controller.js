import { Controller } from "@hotwired/stimulus"

const EMPTY_ANGLE = -90
const FIRST_DURATION = 1350
const UPDATE_DURATION = 650
const lastAngles = new Map()

export default class extends Controller {
  connect() {
    this.needle = this.element.querySelector("[data-remainder-gauge-needle]")
    this.hub = this.element.querySelector("[data-remainder-gauge-hub]")
    this.finalAngle = this.#angleFrom(this.needle)
    const gaugeIndex = [...document.querySelectorAll("[data-daily-gauge]")].indexOf(this.element)
    this.gaugeKey = `${window.location.pathname}:${gaugeIndex}`

    if (!this.needle || !this.hub || this.finalAngle === null || this.#reduceMotion) return
    if (!("IntersectionObserver" in window)) return

    this.startAngle = lastAngles.get(this.gaugeKey) ?? EMPTY_ANGLE
    this.isFirstAppearance = !lastAngles.has(this.gaugeKey)
    lastAngles.set(this.gaugeKey, this.finalAngle)

    if (this.startAngle === this.finalAngle) return

    this.#rotateTo(this.startAngle)
    this.observer = new IntersectionObserver(this.#observe, { threshold: 0.35 })
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
    cancelAnimationFrame(this.animationFrame)
    if (this.needle && this.hub && this.finalAngle !== null) this.#rotateTo(this.finalAngle)
  }

  #observe = (entries) => {
    if (!entries.some((entry) => entry.isIntersecting && entry.intersectionRatio >= 0.35)) return

    this.observer.disconnect()
    this.startedAt = null
    this.animationFrame = requestAnimationFrame(this.#animate)
  }

  #animate = (timestamp) => {
    this.startedAt ||= timestamp
    const duration = this.isFirstAppearance ? FIRST_DURATION : UPDATE_DURATION
    const progress = Math.min((timestamp - this.startedAt) / duration, 1)

    this.#rotateTo(this.#angleAt(progress))

    if (progress < 1) {
      this.animationFrame = requestAnimationFrame(this.#animate)
    } else {
      this.#rotateTo(this.finalAngle)
    }
  }

  #angleAt(progress) {
    const keyframes = this.isFirstAppearance ? [
      [0, this.startAngle],
      [0.55, this.finalAngle + 13],
      [0.7, this.finalAngle - 8],
      [0.82, this.finalAngle + 5],
      [0.91, this.finalAngle - 2.5],
      [1, this.finalAngle]
    ] : [
      [0, this.startAngle],
      [0.72, this.finalAngle + Math.sign(this.finalAngle - this.startAngle) * 4],
      [0.88, this.finalAngle - Math.sign(this.finalAngle - this.startAngle) * 2],
      [1, this.finalAngle]
    ]

    const frameIndex = keyframes.findIndex(([position]) => position >= progress)
    const [endPosition, endAngle] = keyframes[frameIndex]
    const [startPosition, startAngle] = keyframes[Math.max(frameIndex - 1, 0)]
    const segmentProgress = (progress - startPosition) / (endPosition - startPosition || 1)
    const easedProgress = segmentProgress * segmentProgress * (3 - 2 * segmentProgress)

    return startAngle + (endAngle - startAngle) * easedProgress
  }

  #rotateTo(angle) {
    const transform = `rotate(${angle} 120 118)`
    this.needle.setAttribute("transform", transform)
    this.hub.setAttribute("transform", transform)
  }

  #angleFrom(element) {
    const match = element?.getAttribute("transform")?.match(/rotate\(([-\d.]+)/)
    return match ? Number.parseFloat(match[1]) : null
  }

  get #reduceMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
