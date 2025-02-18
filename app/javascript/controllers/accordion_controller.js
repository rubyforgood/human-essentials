import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="accordion"
// Intercepts form submission and disables the open/close section buttons.
export default class extends Controller {
  static targets = [ "form" ]

  disableOpenClose(event) {
    event.preventDefault();

    const buttons = this.element.querySelectorAll(".accordion-button");
    buttons.forEach(button => {
      button.disabled = true;
      button.classList.add("saving");
    });

    this.formTarget.requestSubmit();
  }
}
