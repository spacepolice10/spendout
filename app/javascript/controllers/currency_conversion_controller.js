import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "amount", "currency", "rate", "rateBase", "rateQuote", "rateCode", "rateFields", "result" ]
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
    this.syncRateCode()
    this.calculate()
  }

  calculateFromBase() {
    queueMicrotask(() => this.renderFromBase())
  }

  calculateFromQuote() {
    queueMicrotask(() => this.renderFromQuote())
  }

  swapPair() {
    const base = this.parsedAmount(this.rateBaseTarget.value)
    const quote = this.parsedAmount(this.rateQuoteTarget.value)
    if (!(base > 0) || !(quote > 0)) return

    this.setRate(this.canonicalize(base / quote))
    this.setFieldValue(this.rateBaseTarget, this.canonicalize(quote))
    this.setFieldValue(this.rateQuoteTarget, this.canonicalize(base))
    this.render()
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

  renderFromBase() {
    const base = this.parsedAmount(this.rateBaseTarget.value)
    const rate = this.parsedAmount(this.rateTarget.value)
    if (!(base > 0) || !(rate > 0)) return

    this.setFieldValue(this.rateQuoteTarget, this.canonicalize(base * rate))
  }

  renderFromQuote() {
    if (this.rateQuoteTarget.value.trim() === "") return

    const base = this.parsedAmount(this.rateBaseTarget.value)
    const quote = this.parsedAmount(this.rateQuoteTarget.value)
    if (!(base > 0)) return

    this.setRate(this.canonicalize(quote / base))
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

  setFieldValue(field, value) {
    field.value = value
    field.setSelectionRange(value.length, value.length)
    field.dispatchEvent(new InputEvent("input", { bubbles: true }))
  }

  syncRateCode() {
    this.rateCodeTarget.textContent = this.currencyTarget.value
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
