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

 * The modal shows the user what they're about to submit, including items and quantities to distribute.
 * If the user clicks the "Yes..." button from the modal, it submits the form.
 * If the user clicks the "No..." button from the modal, it closes and user remains on the same url.
 */
export default class extends Controller {
  static targets = [
    "modal",
    "form",
    "partnerSelection",
    "storageSelection",
    "partnerName",
    "storageName",
    "itemSelection",
    "quantity",
    "tbody"
  ]

  static values = {
    preCheckPath: String
  }

  openModal(event) {
    event.preventDefault();
    this.debugFormData();

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
        console.log("=== DistributionConfirmationController VALID");
        this.populatePartnerAndStorage();
        this.populateItemsAndQuantities();
        $(this.modalTarget).modal("show");
      } else {
        console.log("=== DistributionConfirmationController INVALID");
        this.formTarget.requestSubmit();
      }
    })
    .catch((error) => {
      // Something went wrong trying to talk to server validation endpoint
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

  populatePartnerAndStorage() {
    const partnerName = this.partnerSelectionTarget.selectedOptions[0].text;
    const storageName = this.storageSelectionTarget.selectedOptions[0].text;
    this.partnerNameTarget.textContent = partnerName;
    this.storageNameTarget.textContent = storageName;
  }

  populateItemsAndQuantities() {
    let itemsHtml = "";
    this.itemSelectionTargets.forEach((itemSel, index) => {
      const itemName = itemSel.selectedOptions[0].text;
      const itemQuantity = this.quantityTargets[index].value;
      itemsHtml += `<tr><td>${itemName}</td><td>${itemQuantity}</td></tr>`;
    });
    this.tbodyTarget.innerHTML = itemsHtml;
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
