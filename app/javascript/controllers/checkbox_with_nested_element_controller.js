import { Controller } from "@hotwired/stimulus"

/*
 * CheckboxWithNestedElementController is a Stimulus controller that
 * shows/hides a nested element when a checkbox is checked/unchecked.
 */
export default class extends Controller {
  static targets = [ "nestedElement", "checkbox" ]

  connect() {
    this.toggleNestedElementVisibility()
  }

  /**
   * Toggles the visibility of the nested element depending
   * on wither the checkbox is checked or not.
   */
  toggleNestedElementVisibility() {
    this.nestedElementTarget.classList.toggle("d-none", !this.checkboxTarget.checked)
  }

}

