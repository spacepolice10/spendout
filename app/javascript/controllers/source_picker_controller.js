import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog", "trigger", "summary", "option" ]

  open() {
    if (!this.dialogTarget.open) this.dialogTarget.showModal()
    const selected = this.optionTargets.find(option => option.querySelector("input").checked)
    this.activate(selected || this.optionTargets[0])
    queueMicrotask(() => this.activeOption?.focus())
  }

  close() { this.dialogTarget.close() }

  closed() {
    this.activate(null)
    this.triggerTarget.focus()
  }

  select(event) {
    const option = event.currentTarget
    const input = option.querySelector("input")
    input.checked = true
    input.dispatchEvent(new Event("change", { bubbles: true }))
    this.summaryTarget.textContent = option.dataset.selectionValue
    this.optionTargets.forEach(candidate => candidate.setAttribute("aria-selected", String(candidate === option)))
    this.dialogTarget.close()
  }

  keydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.dialogTarget.close("cancel")
      return
    }
    if (![ "ArrowDown", "ArrowUp", "Enter" ].includes(event.key)) return

    event.preventDefault()
    if (event.key === "Enter") {
      this.activeOption?.click()
      return
    }

    const currentIndex = this.optionTargets.indexOf(this.activeOption)
    const offset = event.key === "ArrowDown" ? 1 : -1
    const nextIndex = currentIndex === -1 ? 0 :
      (currentIndex + offset + this.optionTargets.length) % this.optionTargets.length
    this.activate(this.optionTargets[nextIndex])
    this.activeOption.focus()
  }

  activate(option) {
    this.optionTargets.forEach(candidate => candidate.toggleAttribute("data-source-picker-active", candidate === option))
    this.activeOption = option
  }
}
