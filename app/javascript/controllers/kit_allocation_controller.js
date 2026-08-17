import { Controller } from "@hotwired/stimulus"

/*
 * Kit allocation preview.
 *
 * Replaces the inline jQuery that used to live at the bottom of kits/allocations.html.erb.
 * Picking a storage location highlights that row and enables the quantity field; typing a
 * quantity previews the resulting change per item.
 *
 * The preview numbers keep a sign as well as a colour, so the direction of the change is not
 * carried by red/green alone.
 */
export default class extends Controller {
  static targets = ["location", "changeBy", "summary", "row", "preview"]

  connect() {
    this.locationChanged()
  }

  locationChanged() {
    const id = this.locationTarget.value

    this.rowTargets.forEach((row) => {
      row.classList.toggle("bg-brand-50", Boolean(id) && row.dataset.storageLocationId === id)
    })

    this.changeByTarget.disabled = !id
    this.summaryTarget.classList.toggle("hidden", !id)
  }

  changeByChanged() {
    const changeBy = Number(this.changeByTarget.value || 0)

    this.previewTargets.forEach((cell) => {
      // The kit item itself moves opposite to its contents: allocating a kit consumes the
      // component items and produces the kit.
      const delta = -1 * changeBy * Number(cell.dataset.baseQuantity || 0)
      cell.textContent = delta > 0 ? `+${delta}` : String(delta)
      cell.classList.remove("text-emerald-700", "text-rose-700", "text-slate-500")
      if (delta > 0) {
        cell.classList.add("text-emerald-700")
      } else if (delta < 0) {
        cell.classList.add("text-rose-700")
      } else {
        cell.classList.add("text-slate-500")
      }
    })
  }
}
