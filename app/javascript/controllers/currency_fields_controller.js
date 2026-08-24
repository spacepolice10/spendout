import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "amount", "currency", "rate", "converted", "rateFields", "rateStatus" ]
  static values = {
    baseCurrency: String,
    operation: { type: String, default: "divide" },
    referenceUrl: String
  }

  connect() {
    this.previousCurrency = this.currencyTarget.value
    this.validateCurrency()
    this.updateRateFields()
    this.updateInitialRateStatus()
    this.calculate()
  }

  async currencyChanged() {
    const selectedCurrency = this.currencyTarget.value
    this.validateCurrency()

    if (selectedCurrency === this.baseCurrencyValue) {
      this.setRate("1")
      this.clearRateStatus()
    } else {
      const suggestedRate = await this.rateBetween(this.baseCurrencyValue, selectedCurrency)
      if (this.currencyTarget.value !== selectedCurrency) return

      if (suggestedRate) {
        this.setRate(suggestedRate)
        this.clearRateStatus()
      } else {
        this.setRate("")
        this.rateStatusTarget.textContent = "Reference rate unavailable. Enter a rate manually."
      }
    }

    this.previousCurrency = this.currencyTarget.value
    this.updateRateFields()
    this.calculate()
  }

  validateCurrency() {
    const sameCurrencyExchange = this.operationValue === "multiply" &&
      this.currencyTarget.value === this.baseCurrencyValue

    this.currencyTarget.setCustomValidity(
      sameCurrencyExchange ? "Choose a currency different from the source currency." : ""
    )
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
    this.rateTarget.dataset.amountFieldsStartValue = value
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

  async rateBetween(from, to) {
    const rates = await this.referenceRates()
    const fromRate = Number(rates[from])
    const toRate = Number(rates[to])
    if (!Number.isFinite(fromRate) || !Number.isFinite(toRate) || fromRate <= 0 || toRate <= 0) return null

    return this.canonicalize(toRate / fromRate)
  }

  async referenceRates() {
    if (this.referenceRatesPromise) return this.referenceRatesPromise

    const request = new URL(this.referenceUrlValue, window.location.origin)
    request.searchParams.set("base", "USD")

    this.referenceRatesPromise = (async () => {
      const response = await fetch(request, { headers: { Accept: "application/json" } })
      if (!response.ok) return {}

      return (await response.json()).rates || {}
    })().catch(() => ({}))

    return this.referenceRatesPromise
  }
}
