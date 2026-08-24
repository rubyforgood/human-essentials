import { Controller } from "@hotwired/stimulus";

/*
 * Reveals the full text of a table cell that `.notes` has clipped.
 *
 * `.data-table .notes` caps a free-text column at 16rem and clips it, which is what keeps a table
 * of comments scannable -- see design.md, Long text in a table. This gives the clipped text back
 * on demand, which is the half of the pattern Carbon, Ant Design, AG Grid and Salesforce all ship
 * alongside the truncation.
 *
 * Three decisions worth knowing:
 *
 * ONLY WHERE IT IS ACTUALLY CLIPPED. A tooltip repeating text you can already read is noise, and
 * making every cell focusable would add a tab stop per row -- 42 of them on /adjustments.
 * `scrollWidth > clientWidth` per cell means only the cells hiding something become interactive.
 *
 * THE BUBBLE IS `aria-hidden`, AND THE CELL GETS NO `aria-describedby`. CSS clipping is visual
 * only: the whole string is in the DOM and a screen reader has already read it. Describing the
 * cell with a copy of its own text would announce it twice -- which is the main thing wrong with
 * the `title` attribute, and it would be no better for being ours.
 *
 * WCAG 1.4.13 is the reason this is a controller and not a `title`. Content shown on hover or
 * focus must be dismissible (Escape, without moving the pointer), hoverable (you can move onto it
 * to read or select the text) and persistent (no timeout). A `title` is none of those, and shows
 * nothing at all on keyboard focus.
 */
export default class extends Controller {
  connect() {
    this.bubble = null;
    this.anchor = null;

    this.scan = this.scan.bind(this);
    this.onOver = this.onOver.bind(this);
    this.onOut = this.onOut.bind(this);
    this.onFocus = this.onFocus.bind(this);
    this.onBlur = this.onBlur.bind(this);
    this.onKey = this.onKey.bind(this);
    this.hide = this.hide.bind(this);

    this.element.addEventListener("mouseover", this.onOver);
    this.element.addEventListener("mouseout", this.onOut);
    this.element.addEventListener("focusin", this.onFocus);
    this.element.addEventListener("focusout", this.onBlur);
    document.addEventListener("keydown", this.onKey);
    // A fixed bubble does not follow a cell that scrolls away, in the page or inside
    // `.table-scroll`. Capture, because a scroll event on the region does not bubble.
    document.addEventListener("scroll", this.hide, true);
    window.addEventListener("resize", this.scan);
    document.addEventListener("turbo:frame-load", this.scan);

    this.scan();
  }

  disconnect() {
    this.hide();
    this.element.removeEventListener("mouseover", this.onOver);
    this.element.removeEventListener("mouseout", this.onOut);
    this.element.removeEventListener("focusin", this.onFocus);
    this.element.removeEventListener("focusout", this.onBlur);
    document.removeEventListener("keydown", this.onKey);
    document.removeEventListener("scroll", this.hide, true);
    window.removeEventListener("resize", this.scan);
    document.removeEventListener("turbo:frame-load", this.scan);
  }

  // Re-run on resize and after a frame swap: a cell clipped at one width is not at another, and
  // the filter bars replace whole tables without a page load.
  scan() {
    this.hide();
    this.element.querySelectorAll("td.notes").forEach((cell) => {
      const clipped = cell.scrollWidth > cell.clientWidth && cell.textContent.trim() !== "";
      if (clipped) {
        cell.dataset.clipped = "true";
        cell.tabIndex = 0;
      } else {
        delete cell.dataset.clipped;
        cell.removeAttribute("tabindex");
      }
    });
  }

  cellFor(target) {
    return target instanceof Element ? target.closest("td.notes[data-clipped]") : null;
  }

  onOver(event) {
    const cell = this.cellFor(event.target);
    if (cell && cell !== this.anchor) this.show(cell);
  }

  onOut(event) {
    const cell = this.cellFor(event.target);
    if (!cell) return;
    // Moving onto the bubble is not leaving -- that is the "hoverable" half of 1.4.13.
    if (this.bubble && this.bubble.contains(event.relatedTarget)) return;
    if (cell.contains(event.relatedTarget)) return;
    this.hide();
  }

  onFocus(event) {
    const cell = this.cellFor(event.target);
    if (cell) this.show(cell);
  }

  onBlur(event) {
    if (this.cellFor(event.target)) this.hide();
  }

  onKey(event) {
    if (event.key === "Escape") this.hide();
  }

  show(cell) {
    this.hide();
    this.anchor = cell;

    const bubble = document.createElement("div");
    bubble.className = "tip-bubble";
    // Not announced: the cell's own text is already complete in the DOM.
    bubble.setAttribute("aria-hidden", "true");
    bubble.textContent = cell.textContent.trim();
    bubble.addEventListener("mouseleave", (event) => {
      if (event.relatedTarget !== cell) this.hide();
    });
    document.body.appendChild(bubble);
    this.bubble = bubble;

    const anchorBox = cell.getBoundingClientRect();
    const box = bubble.getBoundingClientRect();
    const left = Math.max(8, Math.min(anchorBox.left, window.innerWidth - box.width - 8));
    const below = anchorBox.bottom + 6;
    const top = below + box.height > window.innerHeight ? anchorBox.top - box.height - 6 : below;
    bubble.style.left = `${left}px`;
    bubble.style.top = `${Math.max(8, top)}px`;
  }

  hide() {
    this.bubble?.remove();
    this.bubble = null;
    this.anchor = null;
  }
}
