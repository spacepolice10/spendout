import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "currency", "source", "fields", "rate", "rateLabel", "rateStatus", "sourceDebit", "budgetValue" ]
  static values = { sources: Object, budgetCurrency: String, referenceUrl: String }

  connect() {
    this.amountInput = this.element.querySelector("input[name='expense[amount]']")
    this.previousSourceId = this.sourceId
    this.previousCurrency = this.currencyTarget.value
    this.updateFields({ preserveRate: true })
  }

  currencyChanged() {
    this.updateFields({ preserveRate: false })
  }

  refresh(event) {
    const sourceChanged = this.sourceId !== this.previousSourceId
    const currencyChanged = this.currencyTarget.value !== this.previousCurrency

    if (sourceChanged || currencyChanged) {
      this.updateFields({ preserveRate: false })
    } else {
      this.render()
    }
  }

  rateEdited() {
    this.rateStatusTarget.textContent = ""
    this.render()
  }

  async updateFields({ preserveRate }) {
    const source = this.source
    const sourceId = this.sourceId
    const currency = this.currencyTarget.value
    if (!source) return

    const sameCurrency = currency === source.currency
    this.fieldsTarget.hidden = sameCurrency
    this.rateTarget.disabled = sameCurrency
    this.rateTarget.required = !sameCurrency
    this.previousSourceId = this.sourceId
    this.previousCurrency = this.currencyTarget.value

    if (sameCurrency) {
      this.setRate("1")
      this.rateStatusTarget.textContent = ""
    } else {
      this.rateLabelTarget.textContent = `${currency} units per 1 ${source.currency}`
      if (!preserveRate || this.rateTarget.value === "" || this.rateTarget.value === "1") {
        const suggestion = await this.rateBetween(source.currency, currency)
        if (sourceId !== this.sourceId || currency !== this.currencyTarget.value) return

        this.setRate(suggestion || "")
        this.rateStatusTarget.textContent = suggestion ?
          "" :
          "Reference rate unavailable. Enter a rate manually."
      }
    }

    this.render()
  }

  render() {
    const source = this.source
    const amount = this.parse(this.amountInput?.value)
    const directRate = this.parse(this.rateTarget.value)
    const sourceRate = Number(source?.rate)
    const valid = source && Number.isFinite(amount) && Number.isFinite(directRate) &&
      Number.isFinite(sourceRate) && directRate > 0 && sourceRate > 0

    if (!valid) {
      this.sourceDebitTarget.textContent = ""
      this.budgetValueTarget.textContent = ""
      return
    }

    const sourceAmount = amount / directRate
    const baseAmount = sourceAmount / sourceRate
    this.sourceDebitTarget.textContent = `${this.format(sourceAmount)} ${source.currency} from ${this.sourceName}`
    this.budgetValueTarget.textContent = `${this.format(baseAmount)} ${this.budgetCurrencyValue} in this budget`
  }

  setRate(value) {
    this.rateTarget.value = value
    this.rateTarget.dataset.amountFieldsStartValue = value
    this.rateTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  parse(value) {
    const normalized = String(value || "").trim().replaceAll(".", "").replace(",", ".")
    if (normalized === "") return 0
    return Number(normalized)
  }

  format(value) {
    return value.toFixed(4).replace(/\.?0+$/, "")
  }

  get sourceId() {
    return this.sourceTargets.find((input) => input.checked)?.value
  }

  get source() {
    return this.sourcesValue[this.sourceId]
  }

  get sourceName() {
    return this.sourceTargets.find((input) => input.checked)?.closest("label")?.querySelector("strong")?.textContent.trim()
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

  canonicalize(value) {
    return value.toFixed(12).replace(/\.?0+$/, "")
  }
}
