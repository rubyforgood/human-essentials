import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["itemsContainer",  "addTemplate", "addButton"]

  addItem(event) {
    event.preventDefault();
    const content = this.addTemplateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime());
    this.itemsContainerTarget.insertAdjacentHTML("beforeend", content);
  }

  removeItem(event) {
    event.preventDefault();
    const itemToRemove = event.target.closest(this.getRemoveSelector(event));
    if (itemToRemove) {
      if (event.target.dataset.removeSoft === "true") {
        // Optionally handle soft delete logic here
        console.log("Soft delete, handle accordingly.");
      } else {
        itemToRemove.remove();
      }
    }
  }

  getRemoveSelector(event) {
    return event.target.dataset.removeParentSelector;
  }
}
