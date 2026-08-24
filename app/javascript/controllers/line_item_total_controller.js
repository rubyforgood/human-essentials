import { Controller } from "@hotwired/stimulus";

/*
 * The running total under a line item table: "2 items · 36 units".
 *
 * Every inventory app puts a count at the foot of a line item list, and this one had none -- on a
 * ten-line donation there was no way to check what you had entered without adding it up yourself.
 *
 * It watches the rows rather than listening for a specific event, because there are four ways the
 * set can change and only two of them fire anything: typing in a quantity, choosing an item,
 * form-input#addItem inserting a row, and form-input#removeItem either detaching a row or -- for
 * a persisted one -- setting `_destroy` and hiding it with an inline style. A MutationObserver
 * covers the last two without the remove action having to announce itself.
 *
 * Two things keep the observer from feeding itself, and the first version had neither, which hung
 * the page on the first scan:
 *
 *   - it observes the *rows* container, not the whole fieldset, so the summary it writes is
 *     outside what it watches;
 *   - it only writes when the text actually changes.
 *
 * Assigning textContent replaces a text node, which is a childList mutation like any other. With
 * the summary inside the observed subtree that is an unbroken loop, and the tab stops responding
 * -- including to the barcode field that triggered it.
 */
export default class extends Controller {
  static targets = ["summary", "rows"];

  connect() {
    this.recount = this.recount.bind(this);
    this.element.addEventListener("input", this.recount);
    this.element.addEventListener("change", this.recount);

    if (this.hasRowsTarget) {
      this.observer = new MutationObserver(this.recount);
      this.observer.observe(this.rowsTarget, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ["style", "value"],
      });
    }

    this.recount();
  }

  disconnect() {
    this.element.removeEventListener("input", this.recount);
    this.element.removeEventListener("change", this.recount);
    this.observer?.disconnect();
  }

  recount() {
    if (!this.hasSummaryTarget || !this.hasRowsTarget) return;

    let items = 0;
    let units = 0;

    this.rowsTarget.querySelectorAll(".line_item_section").forEach((row) => {
      if (this.dropped(row)) return;

      const item = row.querySelector(".line_item_name");
      if (!item || !item.value) return;

      items += 1;
      const n = parseInt(row.querySelector("[data-quantity]")?.value, 10);
      if (!Number.isNaN(n)) units += n;
    });

    // A soft-removed row is still in the DOM with `_destroy` set; it is not part of the total.
    const text = items === 0 ? "" : `${this.plural(items, "item")} · ${this.plural(units, "unit")}`;
    if (this.summaryTarget.textContent !== text) this.summaryTarget.textContent = text;
  }

  dropped(row) {
    if (row.style.display === "none") return true;
    const destroy = row.querySelector("input[name*='_destroy']");
    return Boolean(destroy && destroy.value === "1");
  }

  plural(n, word) {
    return `${n.toLocaleString()} ${word}${n === 1 ? "" : "s"}`;
  }
}
