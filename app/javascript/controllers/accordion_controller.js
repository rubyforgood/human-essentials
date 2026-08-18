import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="accordion"
// Intercepts form submission and disables the open/close section buttons.
export default class extends Controller {
  static targets = [ "form" ]

  disableOpenClose(event) {
    event.preventDefault();

    // The section headers are the disclosure triggers. They used to be found by Bootstrap's
    // .accordion-button, which no longer exists, so nothing was ever disabled and a second
    // click during the save could reopen a section mid-submit.
    const buttons = this.element.querySelectorAll('[data-action*="disclosure#toggle"]');
    buttons.forEach(button => {
      button.disabled = true;
    });

    this.formTarget.requestSubmit();
  }
}
