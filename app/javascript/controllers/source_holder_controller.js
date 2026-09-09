import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "stack" ]

  connect() {
    if (!this.hasStackTarget) return

    this.stackTarget.scrollTop = this.stackTarget.scrollHeight
    this.element.addEventListener("wheel", this.forwardHorizontalScroll, { passive: false })
  }

  disconnect() {
    this.element.removeEventListener("wheel", this.forwardHorizontalScroll)
  }

  forwardHorizontalScroll = (event) => {
    if (Math.abs(event.deltaX) <= Math.abs(event.deltaY)) return

    const scroller = this.#horizontalScroller
    if (!scroller) return

    event.preventDefault()
    scroller.scrollLeft += event.deltaX
  }

  get #horizontalScroller() {
    let node = this.element.parentElement

    while (node) {
      const { overflowX } = getComputedStyle(node)
      if ((overflowX === "auto" || overflowX === "scroll") && node.scrollWidth > node.clientWidth) {
        return node
      }
      node = node.parentElement
    }
  }
}
