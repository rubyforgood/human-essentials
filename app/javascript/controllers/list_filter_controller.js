import { Controller } from "@hotwired/stimulus"

// A popover holding a list you can type to narrow, for choosing one thing from an unbounded set.
//
// Sibling of month_range_controller and built on the same terms: no form of its own, one hidden
// field, and the change dispatched on that field is what the filter bar's auto-submit acts on.
//
// The filtering is done here rather than on the server because the whole list is already in the
// page -- one row per category -- and a round trip to narrow a list you are holding is slower than
// the typing that started it.
export default class extends Controller {
  static targets = ["query", "list", "option", "empty", "field", "summary"]

  filter() {
    const needle = this.queryTarget.value.trim().toLowerCase()
    let shown = 0
    for (const option of this.optionTargets) {
      const match = !needle || option.dataset.label.includes(needle)
      option.hidden = !match
      if (match) shown++
    }
    // role="status" on the message, so a reader is told the list is empty rather than left to
    // wonder. Toggling `hidden` on a live region is announced when it becomes visible.
    this.emptyTarget.classList.toggle("hidden", shown > 0)
  }

  choose(event) {
    const { value, labelText } = event.currentTarget.dataset
    this.fieldTarget.value = value
    this.summaryTarget.querySelector("span").textContent = labelText
    this.fieldTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.popover?.close()
  }

  get popover() {
    return this.application.getControllerForElementAndIdentifier(this.element, "popover")
  }
}
