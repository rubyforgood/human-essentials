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
 * `data-overflow` gets `start`, `end`, both or neither, and the CSS draws a shadow at whichever edge
 * it names -- see design.md. Directional on purpose: a signal always on both edges is decoration,
 * one only where content is hidden is information.
 *
 * That edge shadow was a white fade to begin with, which on a table whose rows are white moved the
 * background by a mean of 0.28 of 255 while erasing 26% of the text it lay over: invisible, and its
 * only real effect was damage. It is a shadow now, measured at 8.35 with the text untouched.
 *
 * But an edge signal only ever says *there is more*. It cannot say *you can move*, and the platform
 * will not: its scrollbar is an overlay taking 0px, and on five of the seven overflowing tables it
 * is below the fold anyway. So this also draws a rail -- a real horizontal scroll control that rides
 * the fold, as Ant Design, Confluence and Jira all do.
 *
 * Mounted once on the shell rather than on each of the 66 `.table-scroll` regions in the views.
 * `scroll` does not bubble but it does capture, so one listener on the root hears all of them, and
 * a table arriving in a Turbo frame is picked up without the view knowing this exists.
 */
export default class extends Controller {
  connect() {
    this.markAll = this.markAll.bind(this);
    this.onScroll = this.onScroll.bind(this);
    this.onViewportChange = this.onViewportChange.bind(this);

    // Keyed on the region, so a table replaced by Turbo does not leave its rail behind.
    this.rails = new Map();

    this.element.addEventListener("scroll", this.onScroll, true);
    window.addEventListener("scroll", this.onViewportChange, { passive: true });
    window.addEventListener("resize", this.onViewportChange);
    document.addEventListener("turbo:frame-load", this.markAll);
    // `table-stack` fires this when a table starts or stops being a table: what overflows changes
    // with it, and this controller cannot see that for itself.
    window.addEventListener("table:stack-change", this.markAll);

    this.markAll();
  }

  disconnect() {
    this.element.removeEventListener("scroll", this.onScroll, true);
    window.removeEventListener("scroll", this.onViewportChange);
    window.removeEventListener("resize", this.onViewportChange);
    document.removeEventListener("turbo:frame-load", this.markAll);
    window.removeEventListener("table:stack-change", this.markAll);

    this.rails.forEach(({ rail }) => rail.remove());
    this.rails.clear();
  }

  /*
   * Page scrolling moves every rail, so it is throttled to a frame. The region's own scroll is not:
   * it fires far less often and the thumb must not lag the content.
   */
  onViewportChange() {
    if (this.pending) return;
    this.pending = requestAnimationFrame(() => {
      this.pending = null;
      this.markAll();
    });
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
    const pinned = region.querySelector("thead .pin-col");
    if (pinned) {
      if (region.dataset.pinned === undefined) region.dataset.pinned = "";
      /*
       * Where the start-of-scroll shadow begins. It cannot be drawn on the frozen cell itself: the
       * table is `border-collapse: collapse`, under which a box-shadow on a `td` is never painted --
       * a solid red 40px shadow showed 0% of its pixels there and 50.9% on a control div. So the
       * wrapper draws it and this says where the frozen column ends.
       */
      const width = Math.round(pinned.getBoundingClientRect().width);
      const wrapper = region.parentElement;
      if (wrapper && wrapper.style.getPropertyValue("--pin-width") !== `${width}px`) {
        wrapper.style.setProperty("--pin-width", `${width}px`);
      }
    }

    this.layoutRail(region);
  }

  /*
   * One rail per overflowing region, on the body rather than in the card. A card is
   * `overflow: hidden`, and while that does not clip a fixed descendant on its own, a transform
   * anywhere above would -- putting it on the body means the rail cannot be clipped by anything.
   */
  railFor(region) {
    if (this.rails.has(region)) return this.rails.get(region);

    const rail = document.createElement("div");
    rail.className = "table-rail";
    /*
     * Hidden from assistive technology on purpose, exactly as a native scrollbar is. The region is
     * already a focusable `role="region"` with a name and the arrow keys scroll it, so a second tab
     * stop per table would be a duplicate of a path that already works and is already announced.
     * This is the pointer affordance that was missing, and nothing else.
     */
    rail.setAttribute("aria-hidden", "true");

    const track = document.createElement("div");
    track.className = "table-rail-track";
    const thumb = document.createElement("div");
    thumb.className = "table-rail-thumb";
    track.append(thumb);
    rail.append(track);
    document.body.append(rail);

    const entry = { rail, track, thumb };
    this.rails.set(region, entry);
    this.wireRail(region, entry);
    return entry;
  }

  layoutRail(region) {
    const overflows = region.scrollWidth - region.clientWidth > 1;
    if (!overflows || !region.isConnected) {
      // Nothing to scroll: drop the rail and its reserved strip rather than leave either behind.
      const existing = this.rails.get(region);
      if (existing) {
        existing.rail.remove();
        this.rails.delete(region);
      }
      if (region.parentElement) delete region.parentElement.dataset.railed;
      return;
    }

    const { rail, track, thumb } = this.railFor(region);
    const box = region.getBoundingClientRect();
    const height = rail.offsetHeight || 24;

    /*
     * It rides the fold while the table runs past it, and settles *below* the table once the table's
     * end is on screen -- so it is always attached to the part of the table you can see.
     *
     * Below, not over. Placing it at `box.bottom - height` overlaid the last row, and since the rail
     * is a control it takes the pointer: it swallowed the hover on the bottom row's comment cell and
     * the clipped-text tooltip never appeared. Three passing specs caught that. The card reserves a
     * strip for it instead -- `[data-railed]` in the CSS -- so at rest it covers nothing.
     *
     * While the table does run past the fold the rail does float over a row, as Ant Design's and
     * Confluence's both do. That row is the one already cut in half by the bottom of the window.
     */
    const top = Math.min(window.innerHeight - height, box.bottom);
    if (region.parentElement) region.parentElement.dataset.railed = "";
    const onScreen = box.bottom > 0 && top + height > 0 && box.top < window.innerHeight;

    if (onScreen) rail.dataset.visible = "";
    else delete rail.dataset.visible;

    rail.style.left = `${Math.round(box.left)}px`;
    rail.style.width = `${Math.round(box.width)}px`;
    rail.style.top = `${Math.round(top)}px`;

    const travel = region.scrollWidth - region.clientWidth;
    const usable = track.clientWidth;
    const width = Math.max(24, Math.round(usable * (region.clientWidth / region.scrollWidth)));
    thumb.style.width = `${width}px`;
    thumb.style.left = `${Math.round((usable - width) * (travel > 0 ? region.scrollLeft / travel : 0))}px`;
  }

  wireRail(region, { rail, track, thumb }) {
    const scrollTo = (clientX, grab) => {
      const box = track.getBoundingClientRect();
      const travel = region.scrollWidth - region.clientWidth;
      const usable = box.width - thumb.offsetWidth;
      if (usable <= 0) return;
      region.scrollLeft = ((clientX - box.left - grab) / usable) * travel;
    };

    thumb.addEventListener("pointerdown", (event) => {
      // Where in the thumb it was grabbed, so it does not jump to centre under the pointer.
      const grab = event.clientX - thumb.getBoundingClientRect().left;
      thumb.setPointerCapture(event.pointerId);
      rail.dataset.dragging = "";

      const move = (moved) => scrollTo(moved.clientX, grab);
      const done = () => {
        delete rail.dataset.dragging;
        thumb.removeEventListener("pointermove", move);
        thumb.removeEventListener("pointerup", done);
        thumb.removeEventListener("pointercancel", done);
      };
      thumb.addEventListener("pointermove", move);
      thumb.addEventListener("pointerup", done);
      thumb.addEventListener("pointercancel", done);
      event.preventDefault();
    });

    // Clicking the track jumps there, centring the thumb on the click as a native one does.
    track.addEventListener("pointerdown", (event) => {
      if (event.target === thumb) return;
      scrollTo(event.clientX, thumb.offsetWidth / 2);
    });
  }
}
