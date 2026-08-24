import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "amount", "currency", "rate", "converted", "rateFields" ]
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

    this.convertedTarget.textContent = valid ? this.canonicalize(amount / rate) : ""
  }

  parsedAmount(value) {
    const normalized = String(value).trim().replaceAll(".", "").replace(",", ".")
    if (normalized == "") return 0

    return Number(normalized)
  }

  canonicalize(value) {
    let normalized = value.toFixed(12)

    if (normalized.includes(".")) {
      normalized = normalized.replace(/\.?0+$/, "")
    }

    return normalized === "" || normalized === "-" ? "0" : normalized
  }

  setRate(value) {
    this.rateTarget.value = value
    this.calculate()
  }

  updateRateFields() {
    this.rateFieldsTarget.hidden = this.currencyTarget.value === "" ||
      this.currencyTarget.value === this.baseCurrencyValue
  }
}
