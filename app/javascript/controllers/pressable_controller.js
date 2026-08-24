import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  click(event) {
    if (this.#isClickable && !this.#shouldIgnore(event)) {
      event.preventDefault()
      this.element.click()
    }
  }

  focus(event) {
    if (!this.#shouldIgnore(event)) {
      event.preventDefault()
      this.element.querySelector("[data-pressable-focus-target]")?.focus()
    }
  }

  #shouldIgnore(event) {
    return event.defaultPrevented ||
      (event.target.closest("input, textarea, select, [contenteditable]") && !this.#isFormShortcut(event))
  }

  #isFormShortcut(event) {
    return (event.shiftKey && event.key === "Escape") ||
      (event.metaKey && event.key === "Enter")
  }

  get #isClickable() {
    return getComputedStyle(this.element).pointerEvents !== "none" &&
      !this.element.matches(":disabled, [aria-disabled='true']")
  }
}
