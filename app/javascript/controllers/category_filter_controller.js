import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "filterForm", "filter", "options", "option", "allocation", "pendingNameTextform",
    "addButton", "cleanupButton", "template", "pendingCategory", "pendingCategoryName", "summary"
  ]

  connect() {
    const pendingName = this.pendingNameTextformTarget.value.trim()

    if (pendingName) {
      this.renderPendingCategory(pendingName)
    } else {
      this.filter()
    }
  }

  filter() {
    const requestString = this.filterTarget.value.trim().toLocaleLowerCase()
    let matches = 0

    this.optionTargets.forEach(option => {
      const matchesString = requestString === "" || option.dataset.filterValue.toLocaleLowerCase().includes(requestString)
      option.hidden = !matchesString
      if (matchesString) matches += 1
    })

    const noAllocations = this.optionTargets.length === 0
    const nothingMatched = requestString !== "" && matches === 0
    this.addButtonTarget.hidden = !noAllocations && !nothingMatched
    this.cleanupButtonTarget.hidden = !nothingMatched
  }

  createPendingCategory() {
    const value = this.filterTarget.value.trim()
    if (!value) {
      this.filterTarget.focus()
      return
    }

    this.allocationTargets.forEach(input => input.checked = false)
    this.pendingNameTextformTarget.value = value
    this.renderPendingCategory(value)
  }

  removePendingCategory() {
    this.pendingCategoryTarget.remove()
    this.pendingNameTextformTarget.value = ""
    this.filterTarget.value = ""
    this.filterFormTarget.hidden = false
    this.summaryTarget.textContent = "No allocation"
    this.filter()
    this.filterTarget.focus()
  }

  cleanup() {
    this.filterTarget.value = ""
    this.filter()
    this.filterTarget.focus()
  }

  selectAllocation(event) {
    if (this.hasPendingCategoryTarget) this.pendingCategoryTarget.remove()

    this.pendingNameTextformTarget.value = ""
    this.filterTarget.value = ""
    this.filterFormTarget.hidden = false
    this.summaryTarget.textContent = event.currentTarget.closest("label").dataset.filterValue
    this.filter()
  }

  renderPendingCategory(name) {
    if (this.hasPendingCategoryTarget) this.pendingCategoryTarget.remove()

    const category = this.templateTarget.content.cloneNode(true)
    category.querySelector('[data-category-filter-target~="pendingCategoryName"]').textContent = name
    this.optionsTarget.append(category)
    this.filterFormTarget.hidden = true
    this.summaryTarget.textContent = name
  }
}
