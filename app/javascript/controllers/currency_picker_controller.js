import { Controller } from "@hotwired/stimulus"

const MAX_VISIBLE = 7

export default class extends Controller {
  static targets = ["select", "filter", "option", "radio", "emptyState"]

  connect() {
    this.markSelected()
    this.filter()
  }

  filter() {
    const query = this.filterTarget.value.trim().toLocaleLowerCase()
    let visible = 0

    this.optionTargets.forEach((option) => {
      const matches = option.dataset.filterValue.toLocaleLowerCase().includes(query)
      const wanted = query === "" ? this.isPopular(option) : matches
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
    this.radioTargets.forEach((radio) => {
      radio.checked = radio.value === this.selectTarget.value
    })
  }

  isPopular(option) {
    return option.dataset.popular === "true"
  }
}
