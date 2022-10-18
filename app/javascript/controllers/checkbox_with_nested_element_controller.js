import { Controller } from "@hotwired/stimulus"

/*
 * CheckboxWithNestedElementController is a Stimulus controller that
 * shows/hides a nested element when a checkbox is checked/unchecked.
 */
export default class extends Controller {
  static targets = [ "nestedElement", "checkbox" ]

  connect() {
    this.toggleNestedElementVisiblity()
  }

  toggleNestedElementVisiblity() {
    if (this.checkboxTarget.checked) {
      this.nestedElementTarget.classList.remove("hidden")
    } else {
      this.nestedElementTarget.classList.add("hidden")
    }
  }

}

