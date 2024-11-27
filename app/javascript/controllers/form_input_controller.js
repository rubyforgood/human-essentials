import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="form-input"
export default class extends Controller {
  static targets = [
    "addButton",
    "addTemplate",
    "removeContainer",
    "addContainer",
  ];

  // requires data-add-dest-selector to be set on the add button OR
  // data-form-input-target="addContainer" to be set on the add container
  addItem(event) {
    const template = this.addTemplateTarget.content.firstElementChild.outerHTML;
    const dest =
      document.querySelector(event.target.dataset.addDestSelector) ||
      this.addContainerTarget;

    const uniqId = new Date().getTime();
    const rendered = this.setUniqIds(template, uniqId);

    dest.insertAdjacentHTML("beforeend", rendered);

    var afterInsert = new CustomEvent("form-input-after-insert", {
      bubbles: true,
      detail: dest.lastElementChild,
    });

    dest.lastElementChild.scrollIntoView();
    dest.dispatchEvent(afterInsert);
  }

  // requires data-remove-parent-selector to be set on the remove button OR
  // data-form-input-target="removeContainer" to be set on the container to remove
  removeItem(event) {
    const wrapper =
      event.target.closest(event.target.dataset.removeParentSelector) ||
      this.removeContainerTarget;
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
