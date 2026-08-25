import { Controller } from "@hotwired/stimulus";

/*
 * Turns a table into a list of labelled fields when its container is too narrow to be a table.
 *
 * Measured before this existed: **all fifteen tables scrolled sideways at 320px**, and at 375 too.
 * The worst hid **80% of its width** -- `/distributions` needs 1,638px and had 320. `/purchases`
 * needs 1,393px and had 286, so you could see a fifth of it.
 *
 * The written convention had been that tables scroll, on the strength of WCAG 1.4.10 Reflow
 * exempting data tables. That exemption is permission, not advice. And the design system already
 * contradicted itself: the line item row stacks below `sm` with a label per cell, and the reason
 * recorded for it -- four columns at 320px leaves the item picker 72px, which is not a control
 * anyone can use -- applies word for word to nine columns of purchase data at 286px.
 *
 * Driven from JavaScript rather than a `@container` query, though the question it asks is the
 * container's width. A container query would have been the tidier mechanism, and
 * `container-type: inline-size` computes to `contain: layout`, which makes the element a containing
 * block for *fixed* descendants -- and the row action menus are fixed precisely so they can escape
 * this card. Every one of them would have been positioned against the wrong box.
 *
 * Two other things this has to do, and the second is the one implementations of this pattern usually
 * get wrong:
 *
 * - **Supply the labels.** Writing `data-label` by hand means 299 headings across 71 views kept in
 *   step forever. They are copied out of `<thead>` by column index instead, into a real element
 *   rather than a `::before`, because generated content is not reliably announced.
 * - **Restore the table's semantics.** A browser stops exposing rows and cells as a table the moment
 *   `display` is not `table`, and the header row is `display: none` while stacked, so a screen
 *   reader would be left with unlabelled cells in no structure. The roles are set explicitly.
 */

// Available width, in px, below which a table stops being a table. Chosen against the measured
// container widths so the behaviour is monotonic in the viewport: /purchases has 286px of container
// at a 320px viewport, 341 at 375, 590 at 640, 718 at 768 and 702 at 1024 -- the dip at 1024 is the
// sidebar appearing. A threshold of 704 would have stacked 1024 while leaving 768 a table.
const STACK_BELOW = 640;
// And below which the fields themselves go to a single column.
const SINGLE_COLUMN_BELOW = 416;

export default class extends Controller {
  connect() {
    this.refresh = this.refresh.bind(this);
    this.onViewportChange = this.onViewportChange.bind(this);

    window.addEventListener("resize", this.onViewportChange);
    document.addEventListener("turbo:frame-load", this.refresh);

    this.refresh();
  }

  disconnect() {
    window.removeEventListener("resize", this.onViewportChange);
    document.removeEventListener("turbo:frame-load", this.refresh);
  }

  onViewportChange() {
    if (this.pending) return;
    this.pending = requestAnimationFrame(() => {
      this.pending = null;
      this.refresh();
    });
  }

  refresh() {
    this.element.querySelectorAll("table.data-table").forEach((table) => {
      this.prepare(table);
      this.place(table);
    });
  }

  /*
   * Done once per table: the roles, the labels, and a marker on the actions cell. Everything here is
   * idempotent, so a table arriving in a Turbo frame gets it and one that was already done does not
   * pay for it twice.
   */
  prepare(table) {
    if (table.dataset.stackPrepared !== undefined) return;

    const headings = [...table.querySelectorAll("thead th")];
    if (headings.length === 0) return;

    /*
     * The roles native markup already implies. They are redundant at table widths and load-bearing
     * at stacked ones, and there is no way to apply a role conditionally, so they go on always.
     */
    table.setAttribute("role", "table");
    table.querySelectorAll("thead, tbody, tfoot").forEach((group) => {
      group.setAttribute("role", "rowgroup");
    });
    table.querySelectorAll("tr").forEach((row) => row.setAttribute("role", "row"));
    headings.forEach((heading) => heading.setAttribute("role", "columnheader"));

    // An actions column has no heading to borrow -- it is a `sr-only` span -- so it is found here
    // and marked, rather than left to be guessed at by position.
    const labels = headings.map((heading) => {
      const visible = heading.querySelector(".sr-only") ? "" : heading.textContent.trim();
      return visible;
    });

    table.querySelectorAll("tbody tr").forEach((row) => {
      [...row.children].forEach((cell, index) => {
        if (cell.tagName === "TH") {
          cell.setAttribute("role", "rowheader");
        } else {
          cell.setAttribute("role", "cell");
        }
        // A cell spanning columns cannot be labelled from one heading, and a footer total is not a
        // field of a record: leave both alone.
        if (cell.colSpan > 1) return;

        const label = labels[index];
        if (label === undefined) return;
        if (label === "") {
          cell.classList.add("cell-actions");
          return;
        }
        // The identifying column becomes the card's title, so it is not labelled either.
        if (cell.classList.contains("pin-col")) return;
        if (cell.querySelector(":scope > .cell-label")) return;

        const tag = document.createElement("span");
        tag.className = "cell-label";
        tag.textContent = label;
        cell.prepend(tag);
      });
    });

    table.dataset.stackPrepared = "";
  }

  place(table) {
    const region = table.closest(".table-scroll") || table.parentElement;
    if (!region) return;

    // The width the table has to work with. Read off the region's parent, because the region's own
    // `clientWidth` is the same number and this keeps working if a table is ever not in one.
    const available = (region.parentElement || region).clientWidth;
    if (available === 0) return;

    const stacked = available < STACK_BELOW;
    const columns = available < SINGLE_COLUMN_BELOW ? "1" : "2";

    const was = table.dataset.stack;
    if (stacked) {
      table.dataset.stack = columns;
    } else {
      delete table.dataset.stack;
    }

    /*
     * A stacked table does not overflow, so its rail and edge shadow have to go -- and
     * `table_scroll_controller` has no way to know that on its own. On first paint it runs before
     * this one and draws a rail for a table that is about to stop needing it.
     */
    if (was !== table.dataset.stack) {
      window.dispatchEvent(new CustomEvent("table:stack-change"));
    }

    /*
     * A stacked table does not scroll, so the region must stop advertising that it does: a focusable
     * `role="region"` named "Table, scrollable" would be a stray tab stop making a false promise.
     * The attributes are written into 62 views, so they are put back rather than removed for good.
     */
    if (region.classList.contains("table-scroll")) {
      if (stacked) {
        if (region.dataset.wasScrollable === undefined) {
          region.dataset.wasScrollable = "";
          region.removeAttribute("tabindex");
          region.removeAttribute("role");
          region.removeAttribute("aria-label");
        }
      } else if (region.dataset.wasScrollable !== undefined) {
        delete region.dataset.wasScrollable;
        region.setAttribute("tabindex", "0");
        region.setAttribute("role", "region");
        region.setAttribute("aria-label", "Table, scrollable");
      }
    }
  }
}
