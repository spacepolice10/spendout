import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "source" ]
  static values = { sources: Object }

  sourceChanged() {
    const source = this.sourcesValue[this.sourceTargets.find(input => input.checked)?.value]
    if (!source) return

    this.element.querySelector("[data-controller~='currency-fields']")?.dispatchEvent(
      new CustomEvent("currency-fields:base-currency-changed", { detail: source })
    )
  }
}
