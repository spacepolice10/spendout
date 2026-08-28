import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "currency", "source", "fields", "rate" ]
  static values = { sources: Object, referenceLink: String }

  connect() {
    this.events = new AbortController()
    this.currencyTarget.addEventListener("change", this.currencyChanged, { signal: this.events.signal })
    this.updateFields({ preserveRate: true })
  }

  disconnect() { this.events.abort() }

  currencyChanged = () => {
    this.updateFields({ preserveRate: false })
  }

  sourceChanged() {
    const source = this.source
    if (!source) return

    this.currencyTarget.dispatchEvent(new CustomEvent("currency-picker:select", {
      bubbles: true,
      detail: { currency: source.currency }
    }))
  }

  async updateFields({ preserveRate }) {
    const source = this.source
    const sourceId = this.sourceId
    const currency = this.currencyTarget.value
    if (!source) return

    const sameCurrency = currency === source.currency
    const available = !sameCurrency
    this.fieldsTarget.dataset.currencyPickerAvailable = String(available)
    this.fieldsTarget.dispatchEvent(new CustomEvent("currency-rate-picker:availability-changed", {
      bubbles: true,
      detail: { available, baseCurrency: source.currency, currency }
    }))
    this.rateTarget.disabled = sameCurrency
    this.rateTarget.required = !sameCurrency
    if (sameCurrency) {
      this.setRate("1")
    } else {
      if (!preserveRate || this.rateTarget.value === "" || this.rateTarget.value === "1") {
        this.setRate("")
        const suggestion = await this.rateBetween(source.currency, currency)
        if (sourceId !== this.sourceId || currency !== this.currencyTarget.value) return

        this.setRate(suggestion || "")
      }
    }
  }

  setRate(value) {
    this.rateTarget.value = value
    this.rateTarget.dataset.amountFieldsStartValue = value
    this.rateTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  get sourceId() {
    return this.sourceTargets.find((input) => input.checked)?.value
  }

  get source() {
    return this.sourcesValue[this.sourceId]
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

    const request = new URL(this.referenceLinkValue, window.location.origin)
    request.searchParams.set("base", "USD")

    this.referenceRatesPromise = (async () => {
      const response = await fetch(request, { headers: { Accept: "application/json" } })
      if (!response.ok) return {}

      return (await response.json()).rate_catalog || {}
    })().catch(() => ({}))

    return this.referenceRatesPromise
  }

  canonicalize(value) {
    return value.toFixed(12).replace(/\.?0+$/, "")
  }
}
