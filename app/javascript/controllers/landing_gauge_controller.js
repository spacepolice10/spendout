import { Controller } from "@hotwired/stimulus"

const EMPTY_ANGLE = -90
const DURATION = 1350
const KEYFRAMES = [
  [0, EMPTY_ANGLE],
  [0.55, 13],
  [0.7, -8],
  [0.82, 5],
  [0.91, -2.5],
  [1, 0]
]

export default class extends Controller {
  connect() {
    this.needle = this.element.querySelector("[data-remainder-gauge-needle]")
    this.hub = this.element.querySelector("[data-remainder-gauge-hub]")
    this.finalAngle = this.#angleFrom(this.needle)

    if (!this.needle || !this.hub || this.finalAngle === null || this.#reduceMotion) return
    if (!("IntersectionObserver" in window)) return

    this.#rotateTo(EMPTY_ANGLE)
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
    const progress = Math.min((timestamp - this.startedAt) / DURATION, 1)

    this.#rotateTo(this.#angleAt(progress))

    if (progress < 1) {
      this.animationFrame = requestAnimationFrame(this.#animate)
    } else {
      this.#rotateTo(this.finalAngle)
    }
  }

  #angleAt(progress) {
    const frameIndex = KEYFRAMES.findIndex(([position]) => position >= progress)
    const [endPosition, endOffset] = KEYFRAMES[frameIndex]
    const [startPosition, startOffset] = KEYFRAMES[Math.max(frameIndex - 1, 0)]
    const segmentProgress = (progress - startPosition) / (endPosition - startPosition || 1)
    const easedProgress = segmentProgress * segmentProgress * (3 - 2 * segmentProgress)
    const startAngle = startPosition === 0 ? EMPTY_ANGLE : this.finalAngle + startOffset
    const endAngle = endPosition === 0 ? EMPTY_ANGLE : this.finalAngle + endOffset

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
