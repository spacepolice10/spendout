import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["start", "end"]

  connect() {
    this.validate()
  }

  validate() {
    const invalid = this.startTarget.value && this.endTarget.value &&
      this.endTarget.value < this.startTarget.value

    this.endTarget.setCustomValidity(invalid ? "End date must be on or after the start date." : "")
  }
}
