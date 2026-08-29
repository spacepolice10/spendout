import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog", "trigger" ]

  open() {
    delete this.dialogTarget.dataset.closing
    this.dialogTarget.showModal()
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

  closed() {
    delete this.dialogTarget.dataset.closing
    this.triggerTarget.setAttribute("aria-expanded", "false")
  }

  finishClosing() {
    window.clearTimeout(this.closingFallback)
    if (this.dialogTarget.open) this.dialogTarget.close()
  }
}
