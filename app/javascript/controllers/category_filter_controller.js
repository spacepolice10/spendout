import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "filter", "option", "allocation", "createdTextform", "createdButton", "cleanupButton" ]

  connect() {
    this.filter()
  }

  filter(event) {
    if (event) this.createdTextformTarget.value = ""

    const requestString = this.filterTarget.value.trim().toLocaleLowerCase()
    let matches = 0

    this.optionTargets.forEach(option => {
      const matchesString = requestString === "" || option.dataset.filterValue.toLocaleLowerCase().includes(requestString)
      option.hidden = !matchesString
      if (matchesString) matches += 1
    })

    const nothingMatched = requestString !== "" && matches === 0
    this.createdButtonTarget.hidden = !nothingMatched
    this.cleanupButtonTarget.hidden = !nothingMatched
  }

  selectCreatedCategory() {
    const value = this.filterTarget.value.trim()
    if (!value) {
      this.filterTarget.focus()
      return
    }

    this.allocationTargets.forEach(input => input.checked = false)
    this.createdTextformTarget.value = value
    this.filterTarget.value = value
  }

  cleanup() {
    this.filterTarget.value = ""
    this.createdTextformTarget.value = ""
    this.filter()
    this.filterTarget.focus()
  }

  selectAllocation() {
    this.createdTextformTarget.value = ""
    this.filterTarget.value = ""
    this.filter()
  }
}
