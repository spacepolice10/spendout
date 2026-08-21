import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "amount", "rate", "result" ]
  static values = { baseCurrency: String }

  connect() {
    this.calculate()
  }

  calculate() {
    queueMicrotask(() => this.render())
  }

  render() {
    const amount = this.parsedAmount(this.amountTarget.value)
    const rate = Number(this.rateTarget.value)
    const valid = Number.isFinite(amount) && Number.isFinite(rate) && rate > 0

    this.resultTarget.hidden = !valid
    this.resultTarget.textContent = valid ? `= ${this.format(amount * rate)}` : ""
  }

  parsedAmount(value) {
    const normalized = String(value).trim().replaceAll(".", "").replace(",", ".")
    if (normalized === "") return Number.NaN

    return Number(normalized)
  }

  format(value) {
    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: this.baseCurrencyValue,
      maximumFractionDigits: 4
    }).format(value)
  }
}
