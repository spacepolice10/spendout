import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "filter", "option", "allocation", "pendingNameTextform", "creationTip",
    "creationTipName", "summary", "dialog", "trigger", "confirm"
  ]
  static values = { noAllocation: String, submit: String, createSubmit: String }

  connect() {
    const pendingName = this.pendingNameTextformTarget.value.trim()

    if (pendingName) this.filterTarget.value = pendingName
    this.filter()
    this.updateSubmitLabel()
  }

  open() {
    if (!this.dialogTarget.open) this.dialogTarget.showModal()
    this.filterTarget.value = this.pendingNameTextformTarget.value
    this.filter()
    queueMicrotask(() => this.filterTarget.focus())
  }

  close() { this.dialogTarget.close() }

  closed() {
    this.activate(null)
    this.filterTarget.value = this.pendingNameTextformTarget.value
    this.filter()
    this.triggerTarget.focus()
  }

  filter() {
    const requestString = this.filterTarget.value.trim().toLocaleLowerCase()
    this.optionTargets.forEach(option => {
      const matchesString = requestString === "" || (option.dataset.filterValue && option.dataset.filterValue.toLocaleLowerCase().includes(requestString))
      option.closest("[data-category-picker-option]").hidden = !matchesString
    })

    const value = this.filterTarget.value.trim()
    this.creationTipTarget.hidden = !value
    this.creationTipNameTarget.textContent = value
    this.confirmTarget.disabled = !value
    if (!this.activeOption || this.activeOption.closest("[data-category-picker-option]").hidden) this.activate(this.visibleOptions[0] || null)
  }

  confirm() {
    const value = this.filterTarget.value.trim()
    if (!value) return

    this.pendingNameTextformTarget.value = value
    this.allocationTargets.forEach(input => input.checked = false)
    this.summaryTarget.textContent = value
    this.updateSubmitLabel()
    this.dialogTarget.close()
  }

  selectAllocation(event) {
    const option = event.currentTarget
    option.querySelector("input").checked = true
    this.pendingNameTextformTarget.value = ""
    this.filterTarget.value = ""
    this.creationTipTarget.hidden = true
    this.creationTipNameTarget.textContent = ""
    this.filter()
    this.summaryTarget.textContent = option.dataset.selectionValue
    this.markSelected(option)
    this.updateSubmitLabel()
    this.dialogTarget.close()
  }

  keydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.dialogTarget.close("cancel")
      return
    }
    if (!["ArrowDown", "ArrowUp", "Enter"].includes(event.key)) return

    if (event.key === "Enter") {
      event.preventDefault()
      if (this.filterTarget.value.trim()) {
        this.confirm()
      } else if (this.activeOption) {
        this.activeOption.querySelector("input").click()
      }
      return
    }

    const options = this.visibleOptions
    if (options.length === 0) return
    event.preventDefault()
    const currentIndex = options.indexOf(this.activeOption)
    const offset = event.key === "ArrowDown" ? 1 : -1
    const nextIndex = currentIndex === -1 ? (offset === 1 ? 0 : options.length - 1) :
      (currentIndex + offset + options.length) % options.length
    this.activate(options[nextIndex])
  }

  activate(option) {
    this.optionTargets.forEach(candidate => candidate.toggleAttribute("data-category-picker-active", candidate === option))
    this.activeOption = option
    if (option) {
      this.filterTarget.setAttribute("aria-activedescendant", option.id)
      option.scrollIntoView({ block: "nearest" })
    } else {
      this.filterTarget.removeAttribute("aria-activedescendant")
    }
  }

  markSelected(selectedOption) {
    this.optionTargets.forEach(option => option.setAttribute("aria-selected", String(option === selectedOption)))
  }

  updateSubmitLabel() {
    const createsCategory = this.pendingNameTextformTarget.value.trim() !== ""
    this.element.closest("form").querySelector("[data-category-fields-target='submitLabel']").textContent =
      createsCategory ? this.createSubmitValue : this.submitValue
  }

  get visibleOptions() {
    return this.optionTargets.filter(option => !option.closest("[data-category-picker-option]").hidden)
  }
}
