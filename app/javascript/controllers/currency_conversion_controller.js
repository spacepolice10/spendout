import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "amount", "currency", "rate", "converted", "rateFields", "rateStatus" ]
  static values = {
    baseCurrency: String,
    operation: { type: String, default: "divide" },
    rates: { type: Object, default: {} },
    referenceDate: String,
    provider: String
  }

  connect() {
    this.previousCurrency = this.currencyTarget.value
    this.updateRateFields()
    this.updateInitialRateStatus()
    this.calculate()
  }

  currencyChanged() {
    if (this.currencyTarget.value === this.baseCurrencyValue) {
      this.setRate("1")
      this.clearRateStatus()
    } else {
      const suggestedRate = this.ratesValue[this.currencyTarget.value]

      if (suggestedRate) {
        this.setRate(suggestedRate)
        this.rateStatusTarget.textContent = `${this.providerValue} reference rate · ${this.referenceDateValue}`
      } else {
        this.setRate("")
        this.rateStatusTarget.textContent = "Reference rate unavailable. Enter a rate manually."
      }
    }

    this.previousCurrency = this.currencyTarget.value
    this.updateRateFields()
    this.calculate()
  }

  calculate() {
    queueMicrotask(() => this.render())
  }

  rateEdited() {
    this.clearRateStatus()
  }

  render() {
    const amount = this.parsedAmount(this.amountTarget.value)
    const rate = this.parsedAmount(this.rateTarget.value)
    const valid = Number.isFinite(amount) && Number.isFinite(rate) && rate > 0

    const converted = this.operationValue === "multiply" ? amount * rate : amount / rate
    this.convertedTarget.textContent = valid ? this.canonicalize(converted) : ""
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
    this.rateTarget.dataset.moneyInputStartValue = value
    this.rateTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.calculate()
  }

  updateRateFields() {
    this.rateFieldsTarget.hidden = this.currencyTarget.value === "" ||
      this.currencyTarget.value === this.baseCurrencyValue
  }

  updateInitialRateStatus() {
    if (this.currencyTarget.value !== "" &&
        this.currencyTarget.value !== this.baseCurrencyValue &&
        this.rateTarget.value === "") {
      this.rateStatusTarget.textContent = "Reference rate unavailable. Enter a rate manually."
    }
  }

  clearRateStatus() {
    this.rateStatusTarget.textContent = ""
  }
}
