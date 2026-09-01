import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "trigger", "summary", "dialog", "rate", "prompt", "previewLabel" ]
  static values = {
    baseCurrency: String,
    currency: String,
    rateLabelTemplate: String,
    promptTemplate: String,
    emptyRate: String
  }

  connect() {
    this.events = new AbortController()
    const { signal } = this.events
    this.rateTarget.addEventListener("invalid", this.openInvalid, { signal })
    this.rateTarget.addEventListener("change", this.rateChanged, { signal })
    this.element.addEventListener("currency-rate-picker:availability-changed", this.availabilityChanged, { signal })
    this.render()
  }

  disconnect() { this.events.abort() }

  openInvalid = (event) => {
    event.preventDefault()
    this.open()
  }

  open(event) {
    event?.preventDefault()
    this.rateBeforeEdit = this.rateTarget.value
    this.rateStartBeforeEdit = this.rateTarget.dataset.amountFieldsStartValue
    if (!this.dialogTarget.open) this.dialogTarget.showModal()
    queueMicrotask(() => this.rateTarget.focus())
  }

  apply() {
    if (!this.rateTarget.reportValidity()) return
    this.rateTarget.dataset.amountFieldsStartValue = this.rateTarget.value
    this.rateTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.render()
    this.dialogTarget.close("apply")
  }

  hide(event) {
    event?.preventDefault()
    if (this.rateBeforeEdit !== undefined) {
      this.rateTarget.value = this.rateBeforeEdit
      this.rateTarget.dataset.amountFieldsStartValue = this.rateStartBeforeEdit || this.rateBeforeEdit
      this.rateTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }
    if (this.dialogTarget.open) this.dialogTarget.close("cancel")
  }

  hidden() {
    this.render()
    this.triggerTarget.focus()
    this.rateBeforeEdit = undefined
  }

  rateChanged = () => {
    if (!this.dialogTarget.open) this.render()
  }

  availabilityChanged = (event) => {
    this.element.hidden = !event.detail.available
    if (event.detail.baseCurrency) this.baseCurrencyValue = event.detail.baseCurrency
    if (event.detail.currency) this.currencyValue = event.detail.currency
    this.render()
  }

  render() {
    const rate = this.rateTarget.value.trim()
    this.promptTarget.textContent = this.interpolate(this.promptTemplateValue)
    this.previewLabelTarget.textContent = this.interpolate(this.rateLabelTemplateValue)
    this.summaryTarget.value = rate
    this.summaryTarget.placeholder = this.emptyRateValue
  }

  interpolate(template) {
    return template
      .replaceAll("__currency__", this.currencyValue)
      .replaceAll("__base_currency__", this.baseCurrencyValue)
  }
}
