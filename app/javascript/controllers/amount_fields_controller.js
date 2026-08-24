import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    start: String,
    fractionDigits: { type: Number, default: 4 },
    minimum: String,
    minimumExclusive: Boolean,
    maximum: String
  }

  connect() {
    this.events = new AbortController()
    const options = { signal: this.events.signal }

    this.element.addEventListener("input", event => this.handleInputting(event), options)
    this.element.addEventListener("change", event => this.handleInputting(event), options)
    this.element.addEventListener("paste", event => this.handlePasting(event), options)
    this.element.form?.addEventListener("formdata", event => this.handleFormData(event), options)

    this.render(this.parseValue(this.hasStartValue ? this.startValue : this.element.value, "."))
  }

  disconnect() {
    this.events.abort() 
  }

  handleInputting(event) {
    if (event.data === "." && event.inputType === "insertText" && !this.element.value.includes(",")) {
      const caret = this.element.selectionStart
      this.element.setRangeText(",", caret - 1, caret, "end")
    }

    const tokensFromCursor = this.element.value
      .slice(this.element.selectionStart)
      .replace(/[^\d,]/g, "").length

    this.render(this.parseValue(this.element.value, ","))
    this.restoreCursor(tokensFromCursor)
  }

  handlePasting(event) {
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
    this.handleInputting({})
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
    const fractionDigits = fractionValue?.replace(/\D/g, "").slice(0, this.fractionDigitsValue)

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
    } else if (this.canonicalValue !== "" && this.hasMinimumValue) {
      const comparison = this.compare(this.canonicalValue, this.minimumValue)

      if (comparison < 0 || (comparison === 0 && this.minimumExclusiveValue)) {
        message = this.minimumExclusiveValue ?
          `Amount must be greater than ${this.minimumValue}.` :
          `Amount must be greater than or equal to ${this.minimumValue}.`
      }
    }

    if (message === "" && this.canonicalValue !== "" && this.hasMaximumValue &&
        this.compare(this.canonicalValue, this.maximumValue) > 0) {
      message = `Amount must be less than or equal to ${this.maximumValue}.`
    }

    this.element.setCustomValidity(message)
  }

  compare(left, right) {
    const leftParts = this.comparable(left)
    const rightParts = this.comparable(right)
    const scale = Math.max(leftParts.fraction.length, rightParts.fraction.length)
    const leftDigits = `${leftParts.integer}${leftParts.fraction.padEnd(scale, "0")}`
    const rightDigits = `${rightParts.integer}${rightParts.fraction.padEnd(scale, "0")}`
    const leftValue = BigInt(leftDigits || "0") * BigInt(leftParts.sign)
    const rightValue = BigInt(rightDigits || "0") * BigInt(rightParts.sign)

    return leftValue < rightValue ? -1 : leftValue > rightValue ? 1 : 0
  }

  comparable(value) {
    const match = String(value).trim().match(/^(-?)(\d+)(?:\.(\d+))?$/)
    if (!match) return { sign: 1, integer: "0", fraction: "" }

    return {
      sign: match[1] === "-" ? -1 : 1,
      integer: match[2].replace(/^0+(?=\d)/, ""),
      fraction: match[3] || ""
    }
  }

  restoreCursor(tokensFromCursor) {
    let position = this.element.value.length

    while (position > 0 && tokensFromCursor > 0) {
      position--
      if (/[\d,]/.test(this.element.value[position])) tokensFromCursor--
    }

    if (this.element.value[position - 1] === ".") position--
    this.element.setSelectionRange(position, position)
  }

}
