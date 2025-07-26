import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "destination"]
  static values = { valuesToHide: Array }

  connect() {
    this.toggleVisibility()
  }

  sourceChanged() {
    this.toggleVisibility()
  }

  toggleVisibility() {
    const sourceValue = this.sourceTarget.value
    const shouldHide = !sourceValue || this.valuesToHideValue.includes(sourceValue)
    
    this.destinationTargets.forEach(target => {
      if (shouldHide) {
        target.classList.add("d-none")
      } else {
        target.classList.remove("d-none")
      }
    })
  }
}
