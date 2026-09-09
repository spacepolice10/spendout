import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "amount", "currency", "rate", "converted", "rateFields", "rateStatus" ]
  static values = {
    baseCurrency: String,
    operation: { type: String, default: "divide" },
    referenceLink: String
  }

  connect() {
    this.events = new AbortController()
    this.currencyTarget.addEventListener("change", this.currencyChanged, { signal: this.events.signal })
    this.element.addEventListener("currency-fields:base-currency-changed", this.baseCurrencyChanged, { signal: this.events.signal })
    this.updateRateFields()
    this.calculate()
  }

  disconnect() { this.events.abort() }

  currencyChanged = async () => {
    const selectedCurrency = this.currencyTarget.value
    this.updateRateFields()

    if (selectedCurrency === this.baseCurrencyValue) {
      this.setRate("1")
    } else {
      this.setRate("")
      const suggestedRate = await this.rateBetween(this.baseCurrencyValue, selectedCurrency)
      if (this.currencyTarget.value !== selectedCurrency) return

      if (suggestedRate) {
        this.setRate(suggestedRate)
      }
    }

    this.calculate()
  }

  baseCurrencyChanged = (event) => {
    this.baseCurrencyValue = event.detail.currency
    this.currencyChanged()
  }

  calculate() {
    queueMicrotask(() => this.render())
  }

  render() {
    if (!this.hasConvertedTarget) return
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
    this.rateTarget.value = value.replace(".", ",")
    this.rateTarget.dataset.amountFieldsStartValue = value
    this.rateTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.calculate()
  }

  updateRateFields() {
    const available = this.currencyTarget.value !== "" &&
      this.currencyTarget.value !== this.baseCurrencyValue
    this.rateFieldsTarget.dataset.currencyPickerAvailable = String(available)
    this.rateFieldsTarget.dispatchEvent(new CustomEvent("currency-rate-picker:availability-changed", {
      bubbles: true,
      detail: { available, baseCurrency: this.baseCurrencyValue, currency: this.currencyTarget.value }
    }))
  }

  async rateBetween(from, to) {
    const rateCatalog = await this.referenceRates(from)
    const rate = rateCatalog[to]
    if (!Number.isFinite(Number(rate)) || Number(rate) <= 0) return null

    return rate
  }

  async referenceRates(base) {
    this.referenceRatesPromises ||= {}
    if (this.referenceRatesPromises[base]) return this.referenceRatesPromises[base]

    const request = new URL(this.referenceLinkValue, window.location.origin)
    request.searchParams.set("base", base)

    this.referenceRatesPromises[base] = (async () => {
      const response = await fetch(request, { headers: { Accept: "application/json" } })
      if (!response.ok) return {}

      return (await response.json()).rate_catalog || {}
    })().catch(() => ({}))

    return this.referenceRatesPromises[base]
  }
}
