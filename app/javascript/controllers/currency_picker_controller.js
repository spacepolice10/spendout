import { Controller } from "@hotwired/stimulus"

const MAX_VISIBLE = 4

export default class extends Controller {
  static targets = ["select", "filter", "options", "option", "radio", "emptyState", "attachment"]

  connect() {
    this.events = new AbortController()
    this.selectTarget.addEventListener("invalid", this.focusVisibleInput, {
      signal: this.events.signal
    })

    this.markSelected()
    this.showSelection()
    if (this.filterTarget.autofocus) queueMicrotask(() => this.open())
  }

  disconnect() {
    this.events.abort()
  }

  focusVisibleInput = () => {
    requestAnimationFrame(() => {
      this.filterTarget.focus()
      this.open()
    })
  }

  open() {
    this.optionsTarget.hidden = false
    this.filterTarget.setAttribute("aria-expanded", "true")
    this.filter()
    this.filterTarget.select()
  }

  close() {
    this.optionsTarget.hidden = true
    this.emptyStateTarget.hidden = true
    this.filterTarget.setAttribute("aria-expanded", "false")
    this.showSelection()
  }

  search() {
    this.optionsTarget.hidden = false
    this.filterTarget.setAttribute("aria-expanded", "true")
    this.filter()
  }

  filter() {
    const typed = this.filterTarget.value.trim()
    const requestString = typed === this.selectedLabel ? "" : typed.toLocaleLowerCase()
    let visible = 0

    this.optionTargets.forEach((option) => {
      const matches = option.dataset.filterValue.toLocaleLowerCase().includes(requestString)
      const wanted = requestString === "" ? matches && this.isPreselected(option) : matches
      const shown = wanted && visible < MAX_VISIBLE

      option.hidden = !shown
      option.closest("[data-currency-picker-option]").hidden = !shown
      if (shown) visible += 1
    })

    this.emptyStateTarget.hidden = visible > 0
  }

  choose(event) {
    this.selectTarget.value = event.currentTarget.value
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.selectTarget.dispatchEvent(new Event("input", { bubbles: true }))

    this.markSelected()
    this.filterTarget.focus()
    this.close()
  }

  markSelected() {
    let selectedOption

    this.optionTargets.forEach((option) => {
      const input = option.querySelector("input")
      const selected = input.value === this.selectTarget.value

      input.checked = selected
      option.dataset.default = selected ? "true" : null
      option.setAttribute("aria-selected", String(selected))
      if (selected) selectedOption = option
    })

    this.selectedLabel = selectedOption?.dataset.filterValue || ""
  }

  showSelection() {
    this.filterTarget.value = this.selectedLabel || ""
  }

  isPopular(option) {
    return option.dataset.popular === "true"
  }

  isDefault(option) {
    return option.dataset.default === "true"
  }

  isSuggested(option) {
    return option.dataset.suggested === "true"
  }

  isPreselected(option) {
    return this.isPopular(option) || this.isDefault(option) || this.isSuggested(option)
  }
}
