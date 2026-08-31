import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "filter", "option", "allocation", "pendingNameTextform", "creationTip",
    "creationTipName", "summary"
  ]
  static values = { noAllocation: String }

  connect() {
    const pendingName = this.pendingNameTextformTarget.value.trim()

    if (pendingName) this.filterTarget.value = pendingName
    this.filter()
  }

  filter() {
    const requestString = this.filterTarget.value.trim().toLocaleLowerCase()
    this.optionTargets.forEach(option => {
      const matchesString = requestString === "" || option.dataset.filterValue.toLocaleLowerCase().includes(requestString)
      option.hidden = !matchesString
    })

    const value = this.filterTarget.value.trim()
    this.pendingNameTextformTarget.value = value
    this.creationTipTarget.hidden = !value
    this.creationTipNameTarget.textContent = value

    if (value) this.allocationTargets.forEach(input => input.checked = false)
    this.summaryTarget.textContent = value || this.noAllocationValue
  }

  selectAllocation(event) {
    this.pendingNameTextformTarget.value = ""
    this.filterTarget.value = ""
    this.creationTipTarget.hidden = true
    this.creationTipNameTarget.textContent = ""
    this.filter()
    this.summaryTarget.textContent = event.currentTarget.closest("label").dataset.filterValue
  }
}
