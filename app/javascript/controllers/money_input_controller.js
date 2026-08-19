import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { start: String }

  connect() {
    this.events = new AbortController()
    const options = { signal: this.events.signal }

    this.element.addEventListener("input", event => this.handleInput(event), options)
    this.element.addEventListener("change", event => this.handleInput(event), options)
    this.element.addEventListener("paste", event => this.handlePaste(event), options)
    this.element.form?.addEventListener("formdata", event => this.handleFormData(event), options)

    this.render(this.parseValue(this.hasStartValue ? this.startValue : this.element.value, "."))
  }

  disconnect() {
    this.events.abort()
  }

  handleInput(event) {
    if (event.data === "." && event.inputType === "insertText" && !this.element.value.includes(",")) {
      const caret = this.element.selectionStart
      this.element.setRangeText(",", caret - 1, caret, "end")
    }

    const tokensToRight = this.element.value
      .slice(this.element.selectionStart)
      .replace(/[^\d,]/g, "").length

    this.render(this.parseValue(this.element.value, ","))
    this.restoreCursor(tokensToRight)
  }

  handlePaste(event) {
    const value = event.clipboardData?.getData("text")
    if (value == null) return

    event.preventDefault()

    const trimmedValue = value.trim()
    const separator = trimmedValue.includes(",") || /^-?\d{1,3}(\.\d{3})+$/.test(trimmedValue)
      ? ","
      : "."
    const localizedValue = this.localized(this.parseValue(trimmedValue, separator))

    this.element.setRangeText(
      localizedValue,
      this.element.selectionStart,
      this.element.selectionEnd,
      "end"
    )
    this.handleInput({})
  }

  handleFormData(event) {
    event.formData.set(this.element.name, this.canonical(this.parseValue(this.element.value, ",")))
  }

  parseValue(value, separator) {
    const trimmedValue = String(value).trim()
    const negative = trimmedValue.startsWith("-")
    const unsignedValue = trimmedValue.replace(/^-/, "")
    const separatorIndex = unsignedValue.indexOf(separator)
    const integerValue = separatorIndex === -1 ? unsignedValue : unsignedValue.slice(0, separatorIndex)
    const fractionValue = separatorIndex === -1 ? null : unsignedValue.slice(separatorIndex + 1)
    const integerDigits = integerValue.replace(/\D/g, "")
    const fractionDigits = fractionValue?.replace(/\D/g, "").slice(0, 4)

    return {
      empty: integerDigits === "" && !fractionDigits,
      negative,
      integer: integerDigits.replace(/^0+(?=\d)/, "") || "0",
      fraction: fractionDigits,
      hasFraction: fractionValue !== null
    }
  }

  localized(parts) {
    if (parts.empty && !parts.hasFraction) return parts.negative ? "-" : ""

    const sign = parts.negative ? "-" : ""
    const integer = parts.integer.replace(/\B(?=(\d{3})+(?!\d))/g, ".")
    const decimal = parts.hasFraction ? `,${parts.fraction || ""}` : ""

    return `${sign}${integer}${decimal}`
  }

  canonical(parts) {
    if (parts.empty && !parts.hasFraction) return ""

    const sign = parts.negative ? "-" : ""
    const decimal = parts.fraction ? `.${parts.fraction}` : ""

    return `${sign}${parts.integer}${decimal}`
  }

  render(parts) {
    this.element.value = this.localized(parts)
    this.canonicalValue = this.canonical(parts)
    this.validate()
  }

  validate() {
    let message = ""

    if (this.canonicalValue === "" && this.element.value !== "") {
      message = "Enter a valid amount."
    } else if (Number(this.canonicalValue) < 0) {
      message = "Amount must be greater than or equal to 0."
    }

    this.element.setCustomValidity(message)
  }

  restoreCursor(tokensToRight) {
    let position = this.element.value.length

    while (position > 0 && tokensToRight > 0) {
      position--
      if (/[\d,]/.test(this.element.value[position])) tokensToRight--
    }

    if (this.element.value[position - 1] === ".") position--
    this.element.setSelectionRange(position, position)
  }

}
