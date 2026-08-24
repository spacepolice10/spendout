import { Controller } from "@hotwired/stimulus"

const MAX_VISIBLE = 4

export default class extends Controller {
  static targets = ["select", "filter", "options", "option", "radio", "emptyState", "attachment"]

  connect() {
    this.events = new AbortController()
    const { signal } = this.events
    this.selectTarget.addEventListener("invalid", this.focusVisibleInput, {
      signal
    })
    this.element.addEventListener("focusout", this.leave, { signal })
    this.element.addEventListener("currency-picker:availability-changed", this.availabilityChanged, { signal })
    this.optionsTarget.addEventListener("pointerdown", this.beginOptionSelection, { signal })
    document.addEventListener("pointerup", this.endOptionSelection, { signal })
    document.addEventListener("pointercancel", this.endOptionSelection, { signal })

    this.markSelected()
    this.showSelection()
    this.opened = false
    this.attachmentAvailable = this.hasAttachmentTarget &&
      (this.attachmentTarget.dataset.currencyPickerAvailable === "true" || !this.attachmentTarget.hidden)
    this.render()
    if (this.filterTarget.autofocus) queueMicrotask(() => this.open())
  }

  disconnect() {
    this.events.abort()
  }

  focusVisibleInput = () => {
    requestAnimationFrame(() => {
      this.filterTarget.focus()
      this.open()
    })
  }

  open() {
    this.opened = true
    this.render()
    this.filter()
    this.filterTarget.select()
  }

  close() {
    this.opened = false
    this.activeOption = null
    this.showSelection()
    this.render()
  }

  search() {
    this.opened = true
    this.render()
    this.filter()
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.close()
      this.filterTarget.blur()
      return
    }

    if (!["ArrowDown", "ArrowUp", "Enter"].includes(event.key)) return
    if (!this.opened) {
      if (event.key === "Enter") return
      this.open()
    }

    const options = this.visibleOptions
    if (options.length === 0) return

    if (event.key === "Enter") {
      if (!this.activeOption) return

      event.preventDefault()
      event.stopPropagation()
      this.activeOption.querySelector("input").click()
      return
    }

    event.preventDefault()
    const currentIndex = options.indexOf(this.activeOption)
    const offset = event.key === "ArrowDown" ? 1 : -1
    const nextIndex = currentIndex === -1 ? (offset === 1 ? 0 : options.length - 1) :
      (currentIndex + offset + options.length) % options.length
    this.activate(options[nextIndex])
  }

  filter() {
    const typed = this.filterTarget.value.trim()
    const requestString = typed === this.selectedLabel ? "" : typed.toLocaleLowerCase()
    let visible = 0

    this.optionTargets.forEach((option) => {
      const matches = option.dataset.filterValue.toLocaleLowerCase().includes(requestString)
      const wanted = requestString === "" ? matches && this.isPreselected(option) : matches
      const shown = wanted && visible < MAX_VISIBLE

      option.hidden = !shown
      option.closest("[data-currency-picker-option]").hidden = !shown
      if (shown) visible += 1
    })

    this.emptyStateTarget.hidden = visible > 0
    if (this.activeOption?.hidden) this.activate(null)
  }

  choose(event) {
    this.selectTarget.value = event.currentTarget.value
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.selectTarget.dispatchEvent(new Event("input", { bubbles: true }))

    this.markSelected()
    this.close()
    requestAnimationFrame(() => this.finishSelection())
  }

  availabilityChanged = (event) => {
    this.attachmentAvailable = event.detail.available
    this.render()
  }

  beginOptionSelection = () => {
    this.selectingOption = true
  }

  endOptionSelection = () => {
    setTimeout(() => {
      this.selectingOption = false
      if (this.opened && !this.element.contains(document.activeElement)) this.close()
    })
  }

  leave = (event) => {
    if (event.relatedTarget && this.element.contains(event.relatedTarget)) return

    requestAnimationFrame(() => {
      if (!this.selectingOption && !this.element.contains(document.activeElement)) this.close()
    })
  }

  finishSelection() {
    const rate = this.attachmentAvailable && this.hasAttachmentTarget ?
      this.attachmentTarget.querySelector("input") : null

    if (rate && !rate.disabled) {
      rate.focus()
    } else {
      this.filterTarget.focus()
      this.filterTarget.blur()
    }
  }

  activate(option) {
    this.activeOption = option
    if (option) {
      this.filterTarget.setAttribute("aria-activedescendant", option.id)
      option.scrollIntoView({ block: "nearest" })
    } else {
      this.filterTarget.removeAttribute("aria-activedescendant")
    }
  }

  render() {
    this.optionsTarget.hidden = !this.opened
    this.filterTarget.setAttribute("aria-expanded", String(this.opened))
    if (!this.opened) this.emptyStateTarget.hidden = true
    if (this.hasAttachmentTarget) {
      this.attachmentTarget.hidden = this.opened || !this.attachmentAvailable
    }
  }

  get visibleOptions() {
    return this.optionTargets.filter((option) => !option.hidden)
  }

  markSelected() {
    let selectedOption

    this.optionTargets.forEach((option) => {
      const input = option.querySelector("input")
      const selected = input.value === this.selectTarget.value

      input.checked = selected
      option.dataset.default = selected ? "true" : null
      option.setAttribute("aria-selected", String(selected))
      if (selected) selectedOption = option
    })

    this.selectedLabel = selectedOption?.dataset.filterValue || ""
  }

  showSelection() {
    this.filterTarget.value = this.selectedLabel || ""
  }

  isPopular(option) {
    return option.dataset.popular === "true"
  }

  isDefault(option) {
    return option.dataset.default === "true"
  }

  isSuggested(option) {
    return option.dataset.suggested === "true"
  }

  isPreselected(option) {
    return this.isPopular(option) || this.isDefault(option) || this.isSuggested(option)
  }
}
