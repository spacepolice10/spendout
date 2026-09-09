import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog", "trigger", "overlay" ]

  open() {
    if (this.dialogTarget.open) return

    delete this.dialogTarget.dataset.closing
    this.isolatePage()
    this.dialogTarget.show()
    this.dialogTarget.focus({ preventScroll: true })
    this.triggerTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    if (!this.dialogTarget.open || this.dialogTarget.dataset.closing !== undefined) return

    this.dialogTarget.dataset.closing = ""
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return this.finishClosing()

    this.dialogTarget.addEventListener("animationend", () => this.finishClosing(), { once: true })
    this.closingFallback = window.setTimeout(() => this.finishClosing(), 240)
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  cancel(event) {
    event.preventDefault()
    this.close()
  }

  keydown(event) {
    if (event.key !== "Escape" || !this.dialogTarget.open) return

    event.preventDefault()
    this.close()
  }

  preventBackgroundScroll(event) {
    event.preventDefault()
  }

  closed() {
    this.resetDrag()
    this.restorePage()
    delete this.dialogTarget.dataset.closing
    this.triggerTarget.setAttribute("aria-expanded", "false")
    this.triggerTarget.focus({ preventScroll: true })
  }

  disconnect() {
    this.restorePage()
  }

  isolatePage() {
    const pageSiblings = Array.from(document.body.children).filter(element => element !== this.element)
    const menuSiblings = Array.from(this.element.children).filter(element => (
      element !== this.dialogTarget && element !== this.overlayTarget
    ))

    this.inertedElements = [...pageSiblings, ...menuSiblings].filter(element => !element.inert)
    this.inertedElements.forEach(element => { element.inert = true })
  }

  restorePage() {
    this.inertedElements?.forEach(element => { element.inert = false })
    this.inertedElements = undefined
  }

  startDrag(event) {
    if (event.pointerType === "mouse") return

    this.dragPointerId = event.pointerId
    this.dragStartY = event.clientY
    this.dragStartedAt = performance.now()
    this.dragDistance = 0
    this.dragVelocity = 0
    this.didDrag = false
    this.lastDragY = event.clientY
    this.lastDragAt = this.dragStartedAt
    event.currentTarget.setPointerCapture(event.pointerId)
    this.dialogTarget.dataset.dragging = ""
  }

  drag(event) {
    if (event.pointerId !== this.dragPointerId) return

    const now = performance.now()
    const elapsed = Math.max(now - this.lastDragAt, 1)
    this.dragVelocity = (event.clientY - this.lastDragY) / elapsed
    this.lastDragY = event.clientY
    this.lastDragAt = now

    const distance = event.clientY - this.dragStartY
    if (Math.abs(distance) > 6) this.didDrag = true
    if (this.didDrag && event.cancelable) event.preventDefault()
    this.dragDistance = distance < 0 ? -Math.min(Math.abs(distance) * 0.22, 40) : distance
    this.dialogTarget.style.transform = `translateY(${this.dragDistance}px)`
  }

  endDrag(event) {
    if (event.pointerId !== this.dragPointerId) return

    this.suppressNextClick = this.didDrag
    window.setTimeout(() => { this.suppressNextClick = false }, 0)

    const elapsed = Math.max(performance.now() - this.dragStartedAt, 1)
    const averageVelocity = this.dragDistance / elapsed
    const shouldClose = this.dragDistance > Math.min(120, this.dialogTarget.offsetHeight * 0.3) || this.dragVelocity > 0.6 || averageVelocity > 0.6

    if (shouldClose) {
      this.dialogTarget.style.setProperty("--bottom-sheet-close-from", `${this.dragDistance}px`)
      this.dialogTarget.style.removeProperty("transform")
      this.dragPointerId = undefined
      this.close()
    } else {
      this.returnToOpenPosition()
    }
  }

  cancelDrag(event) {
    if (event.pointerId === this.dragPointerId) this.returnToOpenPosition()
  }

  preventClick(event) {
    if (!this.suppressNextClick) return

    event.preventDefault()
    event.stopPropagation()
    this.suppressNextClick = false
  }

  returnToOpenPosition() {
    const current = this.dragDistance || 0
    const projected = this.dragVelocity < -0.15
      ? Math.max(-56, current + this.dragVelocity * 70)
      : current

    this.returnAnimation?.cancel()
    this.dialogTarget.style.removeProperty("transform")
    this.returnAnimation = this.dialogTarget.animate(
      [
        { transform: `translateY(${current}px)`, offset: 0 },
        { transform: `translateY(${projected}px)`, offset: 0.28 },
        { transform: "translateY(0)", offset: 1 }
      ],
      { duration: 300, easing: "cubic-bezier(0.2, 0.9, 0.3, 1)" }
    )
    this.returnAnimation.addEventListener("finish", () => this.resetDrag(), { once: true })
  }

  resetDrag() {
    this.returnAnimation?.cancel()
    this.returnAnimation = undefined
    this.dragPointerId = undefined
    delete this.dialogTarget.dataset.dragging
    this.dialogTarget.style.removeProperty("transform")
    this.dialogTarget.style.removeProperty("transition")
    this.dialogTarget.style.removeProperty("--bottom-sheet-close-from")
  }

  finishClosing() {
    window.clearTimeout(this.closingFallback)
    if (this.dialogTarget.open) this.dialogTarget.close()
  }
}
