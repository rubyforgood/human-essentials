import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["itemsContainer", "template"]

  addNewItem(event) {
    event.preventDefault();
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime());
    this.itemsContainerTarget.insertAdjacentHTML("beforeend", content);
  }

  removeItem(event) {
    event.preventDefault();
    let itemToRemove = event.target.closest(".nested-fields");
    itemToRemove.remove();
  }
}
