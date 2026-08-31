import { Controller } from "@hotwired/stimulus"

// Says which filters are set, next to the button that opens the panel.
//
// A collapsed filter set that does not show what is active is how someone concludes their records
// have disappeared, so the chips are the price of collapsing the panel at all.
//
// Built in the browser rather than rendered by the server, because the bar sits OUTSIDE the
// results frame: filters apply without it re-rendering, so anything the server put here would be
// one filter behind. The export link had exactly that bug.
export default class extends Controller {
  static targets = ["chips", "count", "clear"]

  connect() {
    this.refresh = this.refresh.bind(this)
    this.element.addEventListener("change", this.refresh)
    this.element.addEventListener("input", this.refresh)
    this.refresh()
  }

  disconnect() {
    this.element.removeEventListener("change", this.refresh)
    this.element.removeEventListener("input", this.refresh)
  }

  refresh() {
    const active = this.activeFilters()

    if (this.hasCountTarget) {
      this.countTarget.textContent = String(active.length)
      this.countTarget.hidden = active.length === 0
    }
    if (this.hasClearTarget) this.clearTarget.hidden = active.length === 0
    if (this.hasChipsTarget) this.renderChips(active)
  }

  activeFilters() {
    return [...this.element.elements].flatMap((field) => {
      const label = this.labelFor(field)
      if (!label) return []

      if (field.type === "checkbox") return field.checked ? [{ field, label, value: null }] : []
      // A date input inside the range popover is one half of a range that reports through its own
      // hidden field -- counting it too would chip the same filter twice. This used to skip every
      // date input, which was the same thing while the popover owned all of them; `filter_date`
      // put a standalone one in a bar and it reported nothing, so a page arrived at by a filtered
      // URL showed no chip and no way to clear it.
      // Widened to month, for the trend pages' range: `<input type="month">` is not
      // `type === "date"`, so the two visible fields inside that popover were being counted as
      // filters of their own -- which showed "Clear all" on a page nobody had filtered.
      if (field.type === "date" && field.closest("[data-controller~='date-range']")) return []
      if (field.type === "month" && field.closest("[data-controller~='month-range']")) return []

      // The date range is always set to something, so it only counts as a filter when it is not
      // the range the page would have shown anyway.
      const fallback = field.dataset.defaultValue
      if (fallback !== undefined && field.value === fallback) return []

      return field.value ? [{ field, label, value: this.displayValue(field) }] : []
    })
  }

  renderChips(active) {
    this.chipsTarget.replaceChildren(...active.map(({ field, label, value }) => {
      const chip = document.createElement("span")
      chip.className = "inline-flex items-center gap-1.5 rounded-full border border-slate-300 " +
        "bg-white py-1 pl-3 pr-1.5 text-sm text-slate-700"

      const name = document.createElement("span")
      name.className = "text-slate-500"
      name.textContent = value === null ? label : `${label}:`
      chip.append(name)

      if (value !== null) {
        const shown = document.createElement("span")
        shown.className = "font-medium"
        shown.textContent = value
        chip.append(" ", shown)
      }

      const remove = document.createElement("button")
      remove.type = "button"
      remove.className = "ml-0.5 flex size-5 items-center justify-center rounded-full text-slate-400 " +
        "hover:bg-slate-100 hover:text-slate-700 focus-visible:outline-2 " +
        "focus-visible:outline-offset-2 focus-visible:outline-brand-600"
      remove.setAttribute("aria-label", `Remove the ${label.toLowerCase()} filter`)
      remove.innerHTML = '<i class="bi-x-lg text-xs" aria-hidden="true"></i>'
      remove.addEventListener("click", () => this.clearField(field))
      chip.append(remove)

      return chip
    }))
  }

  // Reset the control and let the change event do the rest: the date range controller updates its
  // hidden field from it, and auto-submit applies the result. Nothing here submits directly.
  clearField(field) {
    if (field.type === "checkbox") {
      field.checked = false
      field.dispatchEvent(new Event("change", { bubbles: true }))
      return
    }

    // The date range's chip resets a whole popover, not one input, so hand it back to the
    // controller that owns it rather than writing its hidden fields from here.
    const dateRange = field.closest("[data-controller~='date-range']")
    if (dateRange && field.dataset.defaultValue) {
      dateRange.querySelector(`[data-preset="${CSS.escape(field.dataset.defaultValue)}"]`)?.click()
      return
    }

    field.value = field.dataset.defaultValue ?? ""
    field.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // data-filter-label for a control that cannot carry a <label>: the date range submits through
  // hidden fields, because its visible control is a button in a popover.
  labelFor(field) {
    return field.dataset.filterLabel || field.labels?.[0]?.textContent.trim() || null
  }

  displayValue(field) {
    if (field.tagName !== "SELECT") return field.value
    return field.options[field.selectedIndex]?.text.trim() ?? field.value
  }
}
