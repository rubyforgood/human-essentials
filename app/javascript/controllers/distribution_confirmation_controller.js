import { Controller } from "@hotwired/stimulus"

/**
 * Connects to data-controller="distribution-confirmation"
 * Displays a confirmation modal with the details of the Distribution form.
 * Launched when the user clicks Save from the Distribution Form.

 * First runs a "pre-check" on the form data to a validation endpoint,
 * which is specified in the controller's `preCheckPathValue` property.
 * If the pre-check passes, it shows the modal. Because the confirmation modal should only be shown
 * when the form data can pass initial validation.
 * If the pre-check fails, it submits the form to the server for full validation and render with the errors.
 *
 * The pre-check validation endpoint also returns the html body to display in the modal if validation passes,
 * which includes the partner the distribution is going to, the storage location the distribution is from,
 * and the items/quantities to be distributed.

 * If the user clicks the "Yes..." button from the modal, it submits the form.
 * If the user clicks the "No..." button from the modal, it closes and user remains on the same url.
 */
export default class extends Controller {
  static targets = [
    "modal",
    "form"
  ]

  static values = {
    preCheckPath: String
  }

  openModal(event) {
    event.preventDefault();

    const formData = new FormData(this.formTarget);
    const formObject = this.buildNestedObject(formData);

    fetch(this.preCheckPathValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json"
      },
      body: JSON.stringify(formObject),
    })
    .then((response) => response.json())
    .then((data) => {
      if (data.valid) {
        this.modalTarget.innerHTML = data.body;
        $(this.modalTarget).modal("show");
      } else {
        this.formTarget.requestSubmit();
      }
    })
    .catch((error) => {
      // Something went wrong in communication to server validation endpoint
      // In this case, just submit the form as if the user had clicked Save.
      // NICE TO HAVE: Send to bugsnag but need to install/configure https://www.npmjs.com/package/@bugsnag/js
      console.log(`=== DistributionConfirmationController ERROR ${error}`);
      this.formTarget.requestSubmit();
    });
  }

  // Prepare the form data for submission as expected by Rails
  buildNestedObject(formData) {
    let formObject = {};

    for (let [key, value] of formData.entries()) {
      const keys = key.split(/[\[\]]+/).filter((k) => k); // Split and filter out empty strings
      keys.reduce((obj, k, i) => {
        if (i === keys.length - 1) {
          obj[k] = value;
        } else {
          obj[k] = obj[k] || {};
        }
        return obj[k];
      }, formObject);
    }

    return formObject;
  }

  debugFormData() {
    const formData = new FormData(this.formTarget);
    let formDataString = "=== DistributionConfirmationController FormData:\n";
    for (const [key, value] of formData.entries()) {
      formDataString += `${key}: ${value}\n`;
    }
    console.log(formDataString);
  }

  submitForm() {
    $(this.modalTarget).modal("hide");
    this.formTarget.requestSubmit();
  }
}
