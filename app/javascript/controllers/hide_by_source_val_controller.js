import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "destination"]
  static values = { 
    valuesToHide: Array,
    valuesToShow: Array 
  }

  connect() {
    this.toggleVisibility()
  }

  sourceChanged() {
    this.toggleVisibility()
  }

  toggleVisibility() {
    const sourceValue = this.sourceTarget.value
    let shouldShow = false

    if (this.hasValuesToShowValue && this.valuesToShowValue.length > 0) {
      shouldShow = this.valuesToShowValue.includes(sourceValue)
    } else if (this.hasValuesToHideValue && this.valuesToHideValue.length > 0) {
      shouldShow = !this.valuesToHideValue.includes(sourceValue)
    }
    if (shouldShow) {
      this.destinationTarget.classList.remove("d-none")
    } else {
      this.destinationTarget.classList.add("d-none")
    }
  }
}
