import { Controller } from "@hotwired/stimulus";

/*
 * Selecting rows, so several can be acted on at once.
 *
 * Reported alongside the frozen actions column: the pain was not only *reaching* a row's actions
 * but repeating the whole trip for every row. Freezing the column removed the travel; this removes
 * the repetition, for the actions that can genuinely be done to a set.
 *
 * The shape is Carbon's `TableBatchActions` -- selecting rows swaps the table's toolbar for a bar
 * naming the count and offering what can be done to them -- which is also what Gmail, GitHub,
 * Linear, Jira and Airtable do. Three details worth knowing:
 *
 * SHIFT-CLICK SELECTS A RANGE. Every one of those products supports it and people arrive expecting
 * it, and without it "select these nine" is nine clicks. The anchor is the last box *clicked*, not
 * the last one checked, which is what makes shift-click-then-shift-click behave.
 *
 * THE HEADER BOX IS `indeterminate` WHEN SOME ARE SELECTED. A checked select-all with three of
 * fifteen chosen claims something untrue, and `indeterminate` is a property rather than an
 * attribute so it can only be set from here.
 *
 * THE COUNT IS ANNOUNCED. The bar appearing is a visual event; `aria-live="polite"` on the count is
 * what makes it an audible one. Escape clears, which is the way out that does not require finding
 * the Cancel button.
 */
export default class extends Controller {
  static targets = ["all", "row", "bar", "count", "action"];

  connect() {
    this.lastClicked = null;
    this.onKey = this.onKey.bind(this);
    document.addEventListener("keydown", this.onKey);
    this.sync();
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKey);
  }

  get selected() {
    return this.rowTargets.filter((box) => box.checked);
  }

  toggleAll() {
    const on = this.allTarget.checked;
    this.rowTargets.forEach((box) => { box.checked = on; });
    this.lastClicked = null;
    this.sync();
  }

  // A row box was clicked. `event.shiftKey` extends from the last one clicked, inclusive, and
  // takes that box's new state -- which is what makes shift-click able to *deselect* a range too.
  toggleRow(event) {
    const box = event.target;
    if (event.shiftKey && this.lastClicked && this.lastClicked !== box) {
      const boxes = this.rowTargets;
      const from = boxes.indexOf(this.lastClicked);
      const to = boxes.indexOf(box);
      boxes.slice(Math.min(from, to), Math.max(from, to) + 1)
        .forEach((other) => { other.checked = box.checked; });
    }
    this.lastClicked = box;
    this.sync();
  }

  clear() {
    this.rowTargets.forEach((box) => { box.checked = false; });
    this.lastClicked = null;
    this.sync();
  }

  onKey(event) {
    // Only when something is selected, so this does not fight a dialog or a menu for the key.
    if (event.key === "Escape" && this.selected.length > 0) this.clear();
  }

  sync() {
    const chosen = this.selected;
    const count = chosen.length;

    if (this.hasAllTarget) {
      this.allTarget.checked = count > 0 && count === this.rowTargets.length;
      this.allTarget.indeterminate = count > 0 && count < this.rowTargets.length;
    }

    /*
     * The bar floats over the list, so nothing else has to move or be covered for it: the filters
     * and the totals button stay exactly where they were and stay usable. It used to replace the
     * filter row, which made the two mutually exclusive -- reported, and wrong.
     *
     * Rendered hidden by the server and revealed here: JavaScript may reveal, never un-draw.
     */
    if (this.hasBarTarget) this.barTarget.hidden = count === 0;
    if (this.hasCountTarget) {
      this.countTarget.textContent = count === 1 ? "1 selected" : `${count} selected`;
    }

    // Each batch action is a link; the chosen ids go on its query string, so the action needs no
    // JavaScript of its own and works as an ordinary navigation.
    const ids = chosen.map((box) => box.value);
    this.actionTargets.forEach((action) => {
      const url = new URL(action.dataset.batchUrl || action.href, window.location.origin);
      url.searchParams.delete("ids[]");
      ids.forEach((id) => url.searchParams.append("ids[]", id));
      if (!action.dataset.batchUrl) action.dataset.batchUrl = action.href;
      action.href = url.pathname + url.search;
      action.setAttribute("aria-disabled", count === 0 ? "true" : "false");
    });
  }
}
