import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="form-input"
export default class extends Controller {
  static targets = ["itemSelect", "requestSelect"]
  static values = {
    // hash of (item ID => hash of (request unit name => request unit plural name))
    "itemUnits": Object,
    "selectedItemUnits": String
  }

  addOption(val, text) {
    let option = document.createElement("option");
    option.value = val;
    option.text = text;
    if (this.selectedItemUnitsValue === val) {
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
    // `hidden`, not `style.display`. Two reasons: an inline style set in `connect()` meant the
    // select was painted and then removed on every load, and the value it set -- `inline` --
    // overrode the `block w-full` every other select in the app has, so the one time it *was*
    // visible it was laid out differently from its neighbours. The server renders the right
    // state; this only ever changes it in response to a choice.
    if (!units || Object.keys(units).length === 0) {
      this.requestSelectTarget.classList.add('hidden');
      this.requestSelectTarget.selectedIndex = -1;
    }
    else {
      this.requestSelectTarget.classList.remove('hidden');
      this.clearOptions()
      this.addOption('-1', 'Please select a unit')
      this.addOption('', 'units')
      for (const [index, [name, displayName]] of Object.entries(Object.entries(units))) {
        this.addOption(name, displayName)
      }
    }
  }

}
