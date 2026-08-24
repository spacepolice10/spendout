import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "summary", "summaryContent"]

  connect() {
    this.abortController = new AbortController()

    this.element.addEventListener("toggle", () => {
      if (this.element.open && document.activeElement === this.summaryTarget) {
        this.focusInput()
      }
    }, { signal: this.abortController.signal })

    this.element.addEventListener("keydown", (event) => {
      if (event.key !== "Enter" || event.isComposing || event.ctrlKey || event.metaKey || event.altKey) return
      if (!this.inputTargets.includes(event.target)) return

      const details = this.formDetails
      const currentIndex = details.indexOf(this.element)
      const nextDetails = details[currentIndex + (event.shiftKey ? -1 : 1)]

      if (!nextDetails) return
      if (!event.shiftKey && !this.reportValidity()) return

      event.preventDefault()
      nextDetails.open = true
      requestAnimationFrame(() => {
        const inputs = Array.from(nextDetails.querySelectorAll('[data-form-details-target~="input"]'))
        const input = inputs.find((input) => input.checked) || inputs[0]
        input?.focus()
      })
    }, { signal: this.abortController.signal })

    document.addEventListener("invalid", (event) => {
      const details = event.target.closest("details")
      if (details && !details.open) {
        details.open = true
      }
    }, true, {
      signal: this.abortController.signal
    })
  }

  disconnect() {
    this.abortController.abort()
  }

  get formDetails() {
    return Array.from(this.element.closest("form")?.querySelectorAll('details[name="form-details"][data-controller~="form-details"]') || [])
  }

  focusInput() {
    if (!this.hasInputTarget) return

    const checkedInput = this.inputTargets.find((input) => input.checked)
    const input = checkedInput || this.inputTarget
    input.focus()
  }

  reportValidity() {
    const invalidInput = this.element.querySelector("input:invalid, select:invalid, textarea:invalid")
    if (!invalidInput) return true

    invalidInput.reportValidity()
    return false
  }

  updateSummaryContent(event) {
    this.summaryContentTarget.textContent = event.target.value
  }
}
