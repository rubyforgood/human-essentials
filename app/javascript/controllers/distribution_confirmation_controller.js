import { Controller } from "@hotwired/stimulus"

/**
 * Connects to data-controller="distribution-confirmation"
 * Displays a confirmation modal with the details of the Distribution form.
 * Launched when the user clicks Save from the Distribution Form.
 * Shows the user what they're about to submit, including items and quantities to distribute.
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

  openModal(event) {
    event.preventDefault();
    this.debugFormData();
    this.populatePartnerAndStorage();
    this.populateItemsAndQuantities();

    $(this.modalTarget).modal("show");
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
