import { Controller } from "@hotwired/stimulus"

const MAX_VISIBLE = 4

export default class extends Controller {
  static targets = ["select", "filter", "option", "radio", "emptyState"]

  connect() {
    this.markSelected()
    this.filter()
  }

  filter() {
    const requestString = this.filterTarget.value.trim().toLocaleLowerCase()
    let visible = 0

    this.optionTargets.forEach((option) => {
      const matches = option.dataset.filterValue.toLocaleLowerCase().includes(requestString)
      const wanted = requestString === "" ? matches && this.isPreselected(option) : matches
      const shown = wanted && visible < MAX_VISIBLE

      option.hidden = !shown
      if (shown) visible += 1
    })

    this.emptyStateTarget.hidden = visible > 0
  }

  choose(event) {
    this.selectTarget.value = event.currentTarget.value
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.selectTarget.dispatchEvent(new Event("input", { bubbles: true }))

    this.markSelected()
  }

  markSelected() {
    this.optionTargets.forEach((option) => {
      const input = option.querySelector("input")
      const selected = input.value === this.selectTarget.value

      input.checked = selected
      option.dataset.default = selected ? "true" : null
    })
  }

  isPopular(option) {
    return option.dataset.popular === "true"
  }

  isDefault(option) {
    return option.dataset.default === "true"
  }

  isPreselected(option) {
    return this.isPopular(option) || this.isDefault(option)
  }
}
