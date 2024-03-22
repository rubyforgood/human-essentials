import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="request-item"
export default class extends Controller {
  static targets = ["addButton", "addDest", "addTemplate"];

  addItem() {
    const template = this.addTemplateTarget.content.firstElementChild.innerHTML;

    const uniqId = new Date().getTime();
    const rendered = this.setUniqIds(template, uniqId);

    this.addDestTarget.insertAdjacentHTML("beforeend", rendered);
  }

  removeItem(event) {
    const wrapper = event.target.closest("tr");
    const removeSoft = event.target.dataset.removeSoft === "false";

    if (removeSoft) {
      wrapper.remove();
    } else {
      const destroyField = wrapper.querySelector("input[name*='_destroy']");
      if (destroyField) destroyField.value = 1;
      wrapper.style.display = "none";
    }
  }

  // This regex replaces [number] with [templateId]
  // or _number_ with _templateId_
  // Ex: name="request[items_attributes][0][name]" => name="request[items_attributes][897123413][name]"
  // Ex: id="request_items_attributes_0_name" => id="request_items_attributes_9871239487_name"
  setUniqIds(template, templateId) {
    return template.replace(
      /([\[_])([0-9]+)([\]_])/g,
      "$1" + templateId + "$3",
    );
  }
}
