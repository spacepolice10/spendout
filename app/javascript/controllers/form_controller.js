import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "focus", "summary", "summaryContent", "autosize"]
  static values = { focusedOnToggle: { type: Boolean, default: true } }

  connect() {
    this.events = new AbortController()
    const { signal } = this.events

    this.element.addEventListener("invalid", this.openInvalidSection, { capture: true, signal })
    this.element.addEventListener("keydown", this.navigate, { signal })
    this.element.addEventListener("toggle", this.focusingOpenedSection, { capture: true, signal })

    requestAnimationFrame(() => this.autosizeTargets.forEach(this.resizeToContent))
  }

  disconnect() {
    this.events.abort()
  }

  navigate = (event) => {
    if (event.key !== "Enter" || event.isComposing || event.ctrlKey || event.metaKey || event.altKey) return
    if (!event.target.matches('[data-form-target~="focus"]')) return

    const section = event.target.closest('[data-form-target~="section"]')
    const currentSection = this.sectionTargets.indexOf(section)
    const nextSection = this.sectionTargets[currentSection + (event.shiftKey ? -1 : 1)]

    if (!nextSection) return
    if (!event.shiftKey && !this.reportValidity(section)) return

    event.preventDefault()
    nextSection.open = true
    requestAnimationFrame(() => this.focusSection(nextSection))
  }

  openInvalidSection = (event) => {
    const section = event.target.closest('[data-form-target~="section"]')
    if (section) section.open = true
  }

  focusingOpenedSection = (event) => {
    if (!this.focusedOnToggleValue) return

    const section = event.target
    if (!section.matches?.('[data-form-target~="section"]') || !section.open) return

    const summary = section.querySelector('[data-form-target~="summary"]')
    if (document.activeElement === summary) this.focusSection(section)
    section.querySelectorAll('[data-form-target~="autosize"]').forEach(this.resizeToContent)
  }

  resizeToContent = (textareaOrEvent) => {
    const textarea = textareaOrEvent.currentTarget || textareaOrEvent
    textarea.style.blockSize = "auto"
    textarea.style.blockSize = `${textarea.scrollHeight}px`
  }

  focusSection(section) {
    const inputs = Array.from(section.querySelectorAll('[data-form-target~="focus"]'))
      .filter((input) => !input.disabled && !input.hidden)
    const input = inputs.find((input) => input.checked) || inputs[0]
    input?.focus()
  }

  reportValidity(section) {
    const invalidInput = section.querySelector("input:invalid, select:invalid, textarea:invalid")
    if (!invalidInput) return true

    invalidInput.reportValidity()
    return false
  }

  updateSummary(event) {
    const summary = event.target
      .closest('[data-form-target~="section"]')
      ?.querySelector('[data-form-target~="summaryContent"]')
    if (summary) summary.textContent = event.target.value
  }
}
