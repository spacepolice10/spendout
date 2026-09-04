import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "prompt" ]
  static values = {
    baseCurrency: String,
    currency: String,
    promptTemplate: String
  }

  connect() {
    this.events = new AbortController()
    this.element.addEventListener("currency-rate-picker:availability-changed", this.availabilityChanged, { signal: this.events.signal })
    this.render()
  }

  disconnect() { this.events.abort() }

  availabilityChanged = (event) => {
    this.element.hidden = !event.detail.available
    if (event.detail.baseCurrency) this.baseCurrencyValue = event.detail.baseCurrency
    if (event.detail.currency) this.currencyValue = event.detail.currency
    this.render()
  }

  render() {
    this.promptTarget.textContent = this.interpolate(this.promptTemplateValue)
  }

  interpolate(template) {
    return template
      .replaceAll("__currency__", this.currencyValue)
      .replaceAll("__base_currency__", this.baseCurrencyValue)
  }
}
