import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "itemsContainer"];

  addItem(event) {
    event.preventDefault();
    let uniqueId = new Date().getTime(); // Ensure a unique key for each new record
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, uniqueId);
    this.itemsContainerTarget.insertAdjacentHTML("beforeend", content);
  }

  removeItem(event) {
    event.preventDefault();
    const itemToRemove = event.target.closest(".nested-fields");
    const destroyInput = itemToRemove.querySelector("input[name*='_destroy']");
    if (destroyInput) {
      destroyInput.value = "1";
    }
    itemToRemove.style.display = "none"; // Hide the element instead of removing to preserve the destroy input
  }
}
