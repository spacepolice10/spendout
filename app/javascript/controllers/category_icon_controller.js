import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "icon", "colour"]
  static values = { keywords: Object, colours: Object }

  connect() {
    this.userChoseIcon = false
    this.userChoseColour = false
  }

  chooseIcon() {
    this.userChoseIcon = true
  }

  chooseColour() {
    this.userChoseColour = true
  }

  suggest() {
    const icon = this.match(this.nameTarget.value)

    if (!this.userChoseIcon) this.select(this.iconTargets, icon, "userChoseIcon")
    if (!this.userChoseColour) this.select(this.colourTargets, this.coloursValue[icon] || "green", "userChoseColour")
  }

  select(targets, value, choiceFlag) {
    const input = targets.find((candidate) => candidate.value === value)
    if (!input || input.checked) return

    input.checked = true
    input.dispatchEvent(new Event("input", { bubbles: true }))
    this[choiceFlag] = false
  }

  match(name) {
    const words = this.normalize(name).split(" ").filter(Boolean)
    const candidates = [...new Set([...words, words.join("")])]
    const joinedName = words.join("")

    for (const [icon, keywords] of Object.entries(this.keywordsValue)) {
      if (keywords.includes(joinedName)) return icon
    }

    const exactMatches = Object.entries(this.keywordsValue).flatMap(([icon, keywords]) =>
      keywords.filter((keyword) => words.includes(keyword)).map((keyword) => [keyword.length, icon])
    )
    if (exactMatches.length) {
      exactMatches.sort((left, right) => right[0] - left[0])
      return exactMatches[0][1]
    }

    for (const [icon, keywords] of Object.entries(this.keywordsValue)) {
      if (keywords.some((keyword) => candidates.some((candidate) =>
        candidate.length >= 4 && keyword.length >= 4 &&
          Math.abs(candidate.length - keyword.length) <= 1 && this.distance(candidate, keyword) <= 1
      ))) return icon
    }

    return "wallet"
  }

  normalize(value) {
    return value.normalize("NFKD").toLocaleLowerCase().replace(/[^a-z0-9]+/g, " ").trim()
  }

  distance(left, right) {
    let previous = Array.from({ length: right.length + 1 }, (_, index) => index)

    for (let row = 1; row <= left.length; row++) {
      const current = [row]
      for (let column = 1; column <= right.length; column++) {
        current[column] = Math.min(
          current[column - 1] + 1,
          previous[column] + 1,
          previous[column - 1] + (left[row - 1] === right[column - 1] ? 0 : 1)
        )
      }
      previous = current
    }

    return previous[right.length]
  }
}
