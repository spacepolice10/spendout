import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "select", "currencyTrigger", "selection", "currencyDialog", "filter", "option", "emptyState"
  ]
  static values = { autofocus: Boolean }

  connect() {
    this.events = new AbortController()
    const { signal } = this.events
    this.selectTarget.addEventListener("invalid", this.openInvalidCurrency, { signal })
    this.element.addEventListener("currency-picker:select", this.selectCurrency, { signal })
    this.markSelected()
    if (this.autofocusValue) queueMicrotask(() => this.openCurrency())
  }

  disconnect() { this.events.abort() }

  openInvalidCurrency = (event) => {
    event.preventDefault()
    this.openCurrency()
  }

  openCurrency() {
    if (!this.currencyDialogTarget.open) this.currencyDialogTarget.showModal()
    this.filterTarget.value = ""
    this.filter()
    queueMicrotask(() => this.filterTarget.focus())
  }

  hideCurrency() { this.currencyDialogTarget.close() }
  currencyHidden() {
    this.activate(null)
    this.currencyTriggerTarget.focus()
  }
  search() { this.filter() }

  selectCurrency = (event) => {
    this.select(event.detail.currency)
  }

  keydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.currencyDialogTarget.close("cancel")
      return
    }
    if (!["ArrowDown", "ArrowUp", "Enter"].includes(event.key)) return
    const options = this.visibleOptions
    if (options.length === 0) return

    if (event.key === "Enter") {
      if (!this.activeOption) return
      event.preventDefault()
      event.stopPropagation()
      this.activeOption.querySelector("input").click()
      return
    }

    event.preventDefault()
    const currentIndex = options.indexOf(this.activeOption)
    const offset = event.key === "ArrowDown" ? 1 : -1
    const nextIndex = currentIndex === -1 ? (offset === 1 ? 0 : options.length - 1) :
      (currentIndex + offset + options.length) % options.length
    this.activate(options[nextIndex])
  }

  filter() {
    const query = this.filterTarget.value.trim().toLocaleLowerCase()
    let visible = 0
    this.optionTargets.forEach((option) => {
      const shown = option.dataset.filterValue.toLocaleLowerCase().includes(query)
      option.hidden = !shown
      option.closest("[data-currency-picker-option]").hidden = !shown
      if (shown) visible += 1
    })
    this.emptyStateTarget.hidden = visible > 0
    if (!this.activeOption || this.activeOption.hidden) this.activate(this.visibleOptions[0] || null)
  }

  choose(event) {
    this.select(event.currentTarget.value)
    this.currencyDialogTarget.close()
  }

  select(currency) {
    this.selectTarget.value = currency
    this.markSelected()
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  activate(option) {
    this.optionTargets.forEach((candidate) => {
      candidate.toggleAttribute("data-currency-picker-active", candidate === option)
    })
    this.activeOption = option
    if (option) {
      this.filterTarget.setAttribute("aria-activedescendant", option.id)
      option.scrollIntoView({ block: "nearest" })
    } else {
      this.filterTarget.removeAttribute("aria-activedescendant")
    }
  }

  markSelected() {
    let selectedOption
    this.optionTargets.forEach((option) => {
      const input = option.querySelector("input")
      const selected = input.value === this.selectTarget.value
      input.checked = selected
      option.setAttribute("aria-selected", String(selected))
      if (selected) selectedOption = option
    })
    this.selectionTarget.textContent = selectedOption?.dataset.filterValue || "Choose a currency"
  }

  get visibleOptions() { return this.optionTargets.filter((option) => !option.hidden) }
}
