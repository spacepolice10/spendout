import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "filter", "option", "emptyState"]

  connect() {
    this.markSelected()
    this.filter()
  }

  filter() {
    const query = this.filterTarget.value.trim().toLocaleLowerCase()
    let visible = 0

    this.optionTargets.forEach((option) => {
      const matches = option.dataset.filterValue.toLocaleLowerCase().includes(query)
      const shown = query === "" ? matches && this.isPopular(option) : matches

      option.hidden = !shown
      if (shown) visible += 1
    })

    this.emptyStateTarget.hidden = visible > 0
  }

  choose(event) {
    const button = event.currentTarget

    this.selectTarget.value = button.value
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.selectTarget.dispatchEvent(new Event("input", { bubbles: true }))

    this.markSelected()
  }

  markSelected() {
    this.optionTargets.forEach((option) => {
      option.dataset.intent =
        option.value === this.selectTarget.value ? "primary" : "secondary"
    })
  }

  isPopular(option) {
    return option.dataset.popular === "true"
  }
}
