import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="form-input"
export default class extends Controller {
  static targets = ["itemSelect", "requestSelect"]
  static values = {
    // hash of (item ID => hash of (request unit name => request unit plural name))
    "itemUnits": Object
  }

  addOption(val, text, selected) {
    let option = document.createElement("option");
    option.value = val;
    option.text = text;
    if (selected) {
      option.selected = true;
    }
    this.requestSelectTarget.appendChild(option);
  }

  clearOptions() {
    while (this.requestSelectTarget.options.length > 0) {
      this.requestSelectTarget.remove(this.requestSelectTarget.options[0])
    }
  }

  connect() {
    this.itemSelected();
  }

  itemSelected() {
    if (!this.hasRequestSelectTarget) {
      return;
    }
    let option = this.itemSelectTarget.options[this.itemSelectTarget.selectedIndex]
    let units = this.itemUnitsValue[option.value]
    if (!units || Object.keys(units).length === 0) {
      this.requestSelectTarget.style.display = 'none';
    }
    else {
      this.requestSelectTarget.style.display = 'inline';
      this.clearOptions()
      this.addOption('', 'Units')
      for (const [index, [name, displayName]] of Object.entries(Object.entries(units))) {
        this.addOption(name, displayName, index === "0")
      }
    }
  }

}
