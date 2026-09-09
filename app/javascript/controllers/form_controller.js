import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "summaryContent"]

  connect() {
    this.events = new AbortController()
    const { signal } = this.events

    this.element.addEventListener("invalid", this.openInvalidSection, { capture: true, signal })
    this.element.addEventListener("input", this.updateMappedSummary, { signal })
    this.element.addEventListener("change", this.updateSummary, { signal })
  }

  disconnect() {
    this.events.abort()
  }

  openInvalidSection = (event) => {
    const section = event.target.closest('[data-form-target~="section"]')
    if (section) section.open = true
  }

  updateSummary = (event) => {
    const section = event.target.closest('[data-form-target~="section"]')
    const name = event.target.dataset.formSummary
    const summary = name ?
      section?.querySelector(`[data-form-summary-content~="${CSS.escape(name)}"]`) :
      section?.querySelector("[data-form-summary-content]") ? null :
        section?.querySelector('[data-form-target~="summaryContent"]')
    if (summary) summary.textContent = event.target.value
  }

  updateMappedSummary = (event) => {
    if (event.target.dataset.formSummary) this.updateSummary(event)
  }
}
