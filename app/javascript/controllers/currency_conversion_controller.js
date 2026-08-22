import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "amount", "currency", "rate", "rateFields", "result" ]
  static values = { baseCurrency: String }

  connect() {
    this.previousCurrency = this.currencyTarget.value
    this.updateRateFields()
    this.calculate()
  }

  currencyChanged() {
    if (this.currencyTarget.value === this.baseCurrencyValue) {
      this.setRate("1")
    } else if (this.previousCurrency === this.baseCurrencyValue) {
      this.setRate("")
    }

    this.previousCurrency = this.currencyTarget.value
    this.updateRateFields()
    this.calculate()
  }

  calculate() {
    queueMicrotask(() => this.render())
  }

  render() {
    const amount = this.parsedAmount(this.amountTarget.value)
    const rate = this.parsedAmount(this.rateTarget.value)
    const valid = Number.isFinite(amount) && Number.isFinite(rate) && rate > 0

    this.resultTarget.hidden = !valid
    this.resultTarget.textContent = valid ? `= ${this.format(amount / rate)}` : ""
  }

  parsedAmount(value) {
    const normalized = String(value).trim().replaceAll(".", "").replace(",", ".")
    if (normalized == "") return 0

    return Number(normalized)
  }

  setRate(value) {
    this.rateTarget.value = value
    this.rateTarget.dispatchEvent(new InputEvent("input", { bubbles: true }))
  }

  updateRateFields() {
    this.rateFieldsTarget.hidden = this.currencyTarget.value === "" ||
      this.currencyTarget.value === this.baseCurrencyValue
  }

  format(value) {
    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: this.baseCurrencyValue,
      maximumFractionDigits: 4
    }).format(value)
  }
}
