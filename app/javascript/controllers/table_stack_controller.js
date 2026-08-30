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
 * **The layout is not decided here any more.** It used to be: this measured the container and wrote
 * `data-stack`, so the browser laid the page out as a table, painted it, and then rebuilt it as
 * cards. Measured with Chrome's `layout-shift` entries at 390px, that cost **CLS 0.658** on
 * /admin/base_items and put six screens past the 0.25 "poor" threshold. A media query is applied
 * before the first paint, so there is nothing to rebuild -- see application.css.
 *
 * A `@container` query would have been tidier still, since the question really is about the
 * container, but `container-type: inline-size` computes to `contain: layout`, which would make the
 * card a containing block for the fixed row-action menus. `@media` has no such effect, and the
 * container is the viewport less 34px at these sizes on every page, so nothing is lost by asking
 * the window instead.
 *
 * What is left here is the part CSS cannot do, and the second of these is the one implementations
 * of this pattern usually get wrong:
 *
 * - **Supply the labels.** Writing `data-label` by hand means 299 headings across 71 views kept in
 *   step forever. They are copied out of `<thead>` by column index instead, into a real element
 *   rather than a `::before`, because generated content is not reliably announced.
 * - **Restore the table's semantics.** A browser stops exposing rows and cells as a table the moment
 *   `display` is not `table`, and the header row is `display: none` while stacked, so a screen
 *   reader would be left with unlabelled cells in no structure. The roles are set explicitly.
 */

// The same breakpoint the stylesheet uses. It is repeated rather than derived because a media query
// is not readable from script, and it is *only* used for the two things CSS cannot do: telling the
// scroll controller that a stacked table no longer overflows, and taking the scroll region's tab
// stop away. If these two ever disagree the symptom is a stray tab stop, not a broken layout.
const STACKED = "(max-width: 689px)";

export default class extends Controller {
  connect() {
    this.refresh = this.refresh.bind(this);
    this.onViewportChange = this.onViewportChange.bind(this);

    // The breakpoint, not every resize: the layout is the stylesheet's job now, and this only has
    // to notice when the answer changes.
    this.query = window.matchMedia(STACKED);
    this.query.addEventListener("change", this.onViewportChange);
    document.addEventListener("turbo:frame-load", this.refresh);

    this.refresh();
  }

  disconnect() {
    this.query.removeEventListener("change", this.onViewportChange);
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
        // The selection column's heading is a checkbox, so it has no text -- and "no text" is the
        // test below for an actions column. Without this the checkbox was given `cell-actions` and
        // stacked into the same corner as the real actions, which measured as CLS 0.312 on
        // /requests. It needs neither a label nor that class; the CSS places it.
        if (cell.classList.contains("select-col")) return;
        if (label === "") {
          cell.classList.add("cell-actions");
          return;
        }
        // The actions column names itself now -- `.cell-actions` is in the markup, because the
        // column is frozen to the right edge and CSS has to be able to select it. Its heading is
        // a visible "Actions", so without this the cell would be given a "Actions" label as
        // though it were a field of the record.
        if (cell.classList.contains("cell-actions")) return;
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

    const stacked = window.matchMedia(STACKED).matches;

    /*
     * A stacked table does not overflow, so its rail and edge shadow have to go -- and
     * `table_scroll_controller` has no way to know that on its own.
     */
    if (this.wasStacked !== stacked) {
      this.wasStacked = stacked;
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
