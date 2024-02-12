import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="request-item"
export default class extends Controller {
  static targets = ["addButton", "addDest", "addTemplate"];

  addItem() {
    const template =
      this.addTemplateTarget.content.cloneNode(true).firstElementChild;

    const templateId = new Date().getTime();
    const rendered = template.innerHTML.replace(
      /([\[_])([0-9]+)([\]_])/g,
      "$1" + templateId + "$3",
    );

    this.addDestTarget.insertAdjacentHTML("beforeend", rendered);
  }

  removeItem(event) {
    const wrapper = event.target.closest("tr");
    const removeSoft = event.target.dataset.removeSoft === "false";

    if (removeSoft) {
      wrapper.remove();
    } else {
      const input = wrapper.querySelector("input[name*='_destroy']");
      input && (input.value = 1);
      wrapper.style.display = "none";
    }
  }
}
