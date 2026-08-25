import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "select", "currencyTrigger", "selection", "currencyDialog", "filter", "option", "radio",
    "emptyState", "attachment", "rateTrigger", "rateSummary", "rateDialog", "rate", "ratePrompt"
  ]
  static values = { baseCurrency: String, autofocus: Boolean }

  connect() {
    this.events = new AbortController()
    const { signal } = this.events
    this.selectTarget.addEventListener("invalid", this.openInvalidCurrency, { signal })
    if (this.hasRateTarget) {
      this.rateTarget.addEventListener("invalid", this.openInvalidRate, { signal })
      this.rateTarget.addEventListener("change", this.rateChanged, { signal })
    }
    this.element.addEventListener("currency-picker:availability-changed", this.availabilityChanged, { signal })
    this.element.addEventListener("currency-picker:select", this.selectCurrency, { signal })
    this.markSelected()
    this.renderRateSummary()
    if (this.autofocusValue) queueMicrotask(() => this.openCurrency())
  }

  disconnect() { this.events.abort() }

  openInvalidCurrency = (event) => {
    event.preventDefault()
    this.openCurrency()
  }

  openInvalidRate = (event) => {
    event.preventDefault()
    this.openRate()
  }

  openCurrency() {
    if (!this.currencyDialogTarget.open) this.currencyDialogTarget.showModal()
    this.filterTarget.value = ""
    this.filter()
    queueMicrotask(() => this.filterTarget.focus())
  }

  closeCurrency() { this.currencyDialogTarget.close() }
  cancelCurrency() { /* Selection commits only when an option is chosen. */ }
  currencyClosed() {
    this.activate(null)
    this.currencyTriggerTarget.focus()
  }
  search() { this.filter() }

  recommend(event) {
    const option = this.optionTargets.find((candidate) =>
      candidate.querySelector("input").value === event.detail.currency
    )
    const wrapper = option?.closest("[data-currency-picker-option]")
    if (wrapper) wrapper.parentElement.prepend(wrapper)
  }

  selectCurrency = (event) => {
    this.selectTarget.value = event.detail.currency
    this.markSelected()
    this.renderRateSummary()
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.selectTarget.dispatchEvent(new Event("input", { bubbles: true }))
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
    this.selectTarget.value = event.currentTarget.value
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.selectTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.markSelected()
    this.renderRateSummary()
    this.currencyDialogTarget.close()
  }

  openRate() {
    this.rateBeforeEdit = this.rateTarget.value
    this.rateStartBeforeEdit = this.rateTarget.dataset.amountFieldsStartValue
    if (!this.rateDialogTarget.open) this.rateDialogTarget.showModal()
    queueMicrotask(() => this.rateTarget.focus())
  }

  applyRate() {
    if (!this.rateTarget.reportValidity()) return
    this.rateTarget.dataset.amountFieldsStartValue = this.rateTarget.value
    this.rateTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.renderRateSummary()
    this.rateDialogTarget.close("apply")
  }

  cancelRate(event) {
    event?.preventDefault()
    if (this.rateBeforeEdit !== undefined) {
      this.rateTarget.value = this.rateBeforeEdit
      this.rateTarget.dataset.amountFieldsStartValue = this.rateStartBeforeEdit || this.rateBeforeEdit
      this.rateTarget.dispatchEvent(new Event("input", { bubbles: true }))
      this.rateTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
    if (this.rateDialogTarget.open) this.rateDialogTarget.close("cancel")
  }

  rateClosed() {
    this.renderRateSummary()
    this.rateTriggerTarget.focus()
    this.rateBeforeEdit = undefined
  }

  rateEdited() { /* Calculations update live; trigger text updates only after Apply. */ }

  rateChanged = () => {
    if (!this.hasRateDialogTarget || !this.rateDialogTarget.open) this.renderRateSummary()
  }

  availabilityChanged = (event) => {
    if (!this.hasAttachmentTarget) return
    this.attachmentTarget.hidden = !event.detail.available
    if (event.detail.baseCurrency) {
      this.attachmentTarget.dataset.currencyPickerBaseCurrency = event.detail.baseCurrency
    }
    this.renderRateSummary()
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

  renderRateSummary() {
    if (!this.hasRateSummaryTarget || !this.hasRateTarget) return
    const rate = this.rateTarget.value.trim()
    const base = this.attachmentTarget.dataset.currencyPickerBaseCurrency || this.baseCurrencyValue
    const selected = this.selectTarget.value
    const prompt = `Enter how many units of ${selected} are in 1 ${base}`
    if (this.hasRatePromptTarget) this.ratePromptTarget.textContent = prompt
    this.rateTarget.setAttribute("aria-label", prompt)
    if (rate === "") {
      this.rateSummaryTarget.textContent = "Enter rate"
      return
    }
    this.rateSummaryTarget.textContent = `1 ${base} = ${rate} ${selected}`
  }

  get visibleOptions() { return this.optionTargets.filter((option) => !option.hidden) }
}
