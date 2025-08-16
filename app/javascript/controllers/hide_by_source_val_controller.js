import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "destination"]
  static values = { valuesToShow: Array }

  connect() {
    this.toggleVisibility()
  }

  sourceChanged() {
    this.toggleVisibility()
  }

  toggleVisibility() {
    const sourceValue = this.sourceTarget.value
    const shouldShow = this.valuesToShowValue.includes(sourceValue)
    
    if (shouldShow) {
      this.destinationTarget.classList.remove("d-none")
    } else {
      this.destinationTarget.classList.add("d-none")
    }
  }
}
