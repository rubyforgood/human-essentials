import { Controller } from "@hotwired/stimulus";

/*
 * Marks each horizontally scrolling table with which edge has content behind it.
 *
 * A wide table is allowed to scroll -- WCAG 1.4.10 Reflow exempts data tables, and every one here
 * sits in a focusable `role="region"` with a name, so the keyboard and a screen reader are both
 * served. What was missing was any signal to someone looking at it with a mouse: measured on
 * `/distributions`, 486px of columns were off screen, the scrollbar was an overlay one taking 0px
 * of height, and there was no fade, shadow or hint of any kind. The audits could not see it either,
 * because an overlay scrollbar is invisible to a computed-style check.
 *
 * `data-overflow` gets `start`, `end`, both or neither, and the CSS draws a fade at whichever edge
 * it names -- see design.md. Directional on purpose: a fade always on both edges is decoration, one
 * only where content is hidden is information.
 *
 * Mounted once on the shell rather than on each of the 66 `.table-scroll` regions in the views.
 * `scroll` does not bubble but it does capture, so one listener on the root hears all of them, and
 * a table arriving in a Turbo frame is picked up without the view knowing this exists.
 */
export default class extends Controller {
  connect() {
    this.markAll = this.markAll.bind(this);
    this.onScroll = this.onScroll.bind(this);

    this.element.addEventListener("scroll", this.onScroll, true);
    window.addEventListener("resize", this.markAll);
    document.addEventListener("turbo:frame-load", this.markAll);

    this.markAll();
  }

  disconnect() {
    this.element.removeEventListener("scroll", this.onScroll, true);
    window.removeEventListener("resize", this.markAll);
    document.removeEventListener("turbo:frame-load", this.markAll);
  }

  onScroll(event) {
    const region = event.target;
    if (region instanceof Element && region.classList.contains("table-scroll")) this.mark(region);
  }

  markAll() {
    this.element.querySelectorAll(".table-scroll").forEach((region) => this.mark(region));
  }

  mark(region) {
    const edges = [];
    // A pixel of slack: sub-pixel layout means scrollLeft rarely reaches an exact 0 or maximum.
    if (region.scrollLeft > 1) edges.push("start");
    if (region.scrollLeft + region.clientWidth < region.scrollWidth - 1) edges.push("end");

    const next = edges.join(" ");
    if (region.dataset.overflow !== next) region.dataset.overflow = next;

    /*
     * Whether the first column is frozen decides what the start of the scroll should look like, so
     * the CSS needs to know. It cannot work this out for itself: `:has()` may not be nested, so
     * there is no way to write "a div whose `.table-scroll` child contains a `.pin-col`".
     *
     * Six of the seven tables that overflow have one.
     */
    if (region.querySelector(".pin-col") && region.dataset.pinned === undefined) {
      region.dataset.pinned = "";
    }
  }
}
