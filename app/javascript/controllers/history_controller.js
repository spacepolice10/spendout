import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  back(event) {
    if (!this.#shouldGoBack(event)) return

    event.preventDefault()
    window.history.back()
  }

  #shouldGoBack(event) {
    return event.button === 0 &&
      !event.metaKey &&
      !event.ctrlKey &&
      !event.shiftKey &&
      !event.altKey &&
      window.history.length > 1
  }
}
