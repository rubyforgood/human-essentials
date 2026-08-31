import { Controller } from "@hotwired/stimulus"

// One searchable, grouped, multi-select list for what the page is about.
//
// It replaces a single-select in the filter bar and a checkbox on every table row -- two controls
// answering the same question, the second of which cost a full page load and 1,702px of lost scroll
// per tick. Here the choices are made in one place and applied once, when the panel closes.
//
// Applied on close, not on change. Four choices are one request rather than four, and the panel
// staying open is what makes choosing four things feel like one action. The date and month pickers
// commit on change because a range is one answer; this one is a set, and a set is not finished until
// you stop adding to it.
export default class extends Controller {
  static targets = ["query", "option", "group", "box", "empty", "count", "summary"]
  static values = { cap: Number }

  connect() {
    this.committed = this.selection()
    // The popover dispatches this when it closes, however it closed -- button, Escape or a click
    // outside. Submitting from here rather than from each of those is what makes all three behave
    // the same.
    this.onClose = () => this.commit()
    this.element.addEventListener("popover:close", this.onClose)
  }

  disconnect() {
    this.element.removeEventListener("popover:close", this.onClose)
  }

  filter() {
    const needle = this.queryTarget.value.trim().toLowerCase()
    let shown = 0
    for (const option of this.optionTargets) {
      const match = !needle || option.dataset.label.includes(needle)
      option.hidden = !match
      if (match) shown++
    }
    // A group heading over nothing is noise, so it goes with its group.
    for (const heading of this.groupTargets) {
      const group = heading.dataset.group
      heading.hidden = !this.optionTargets.some((o) => o.dataset.group === group && !o.hidden)
    }
    this.emptyTarget.classList.toggle("hidden", shown > 0)
  }

  // The cap is enforced here as well as on the server, because a checkbox that lets you tick a
  // fifth and then silently drops it is worse than one that will not be ticked.
  //
  // `stopPropagation` first: these boxes sit inside the filter bar's form, and the bar submits on
  // any change that reaches it. Left to bubble, the first tick navigated immediately -- which is
  // the whole friction this control exists to remove, reintroduced one level down. The date range
  // picker's custom fields do the same thing for the same reason.
  toggle(event) {
    event?.stopPropagation()

    const chosen = this.selection()
    const full = chosen.length >= this.capValue
    for (const box of this.boxTargets) box.disabled = !box.checked && full

    this.countTarget.textContent = chosen.length === 0
      ? `Choose up to ${this.capValue} to compare them.`
      : `${chosen.length} of ${this.capValue} chosen${full ? ". Clear one to add another." : "."}`
  }

  commit() {
    const now = this.selection()
    // Nothing changed, so nothing is worth a page load.
    if (now.length === this.committed.length && now.every((v, i) => v === this.committed[i])) return
    this.element.closest("form").requestSubmit()
  }

  selection() {
    return this.boxTargets.filter((b) => b.checked).map((b) => b.value)
  }
}
