import { Controller } from "@hotwired/stimulus";

/*
 * Names a control that shows only an icon.
 *
 * An icon-only row action needs its name back somehow, and the `title` attribute is not it. It is
 * browser chrome -- unstyleable, different on every OS, and not part of this design system, which
 * is the same objection already made here about a browser-rendered confirm dialog. It also shows
 * **nothing at all on keyboard focus**, waits about a second, vanishes on a timer, and can be
 * neither hovered nor dismissed. That is three failures of WCAG 1.4.13 and no keyboard support.
 *
 * Carbon, Primer, MUI, Ant Design, Salesforce and Atlassian all pair an icon-only button with a
 * component tooltip and none of them uses `title`. This is ours.
 *
 * Three decisions worth knowing:
 *
 * THE BUBBLE IS `aria-hidden` AND THE CONTROL KEEPS ITS `aria-label`. The bubble shows the same
 * string the accessible name already carries, so describing the control with it as well would
 * announce the action twice. Same rule, and the same reason, as the clipped-text bubble.
 *
 * `title` IS REMOVED, NOT LEFT ALONGSIDE. Two tooltips for one control is worse than one, and the
 * native one draws on top of ours a second later. Nothing here renders a `title`, and
 * `bin/design/tooltip-audit.js` fails the build if one comes back.
 *
 * IT OPENS BELOW, AND FLIPS. The actions column is frozen to the right edge, so a bubble opening
 * rightwards would be cut off by the window.
 *
 * Mounted once on the shell, like `clipped-text`: `mouseover` and `focusin` both bubble, so one
 * listener serves every control including any that arrives in a Turbo frame.
 */
export default class extends Controller {
  connect() {
    this.bubble = null;
    this.anchor = null;

    this.onOver = this.onOver.bind(this);
    this.onOut = this.onOut.bind(this);
    this.onFocus = this.onFocus.bind(this);
    this.onBlur = this.onBlur.bind(this);
    this.onKey = this.onKey.bind(this);
    this.onScroll = this.onScroll.bind(this);
    this.hide = this.hide.bind(this);

    this.element.addEventListener("mouseover", this.onOver);
    this.element.addEventListener("mouseout", this.onOut);
    this.element.addEventListener("focusin", this.onFocus);
    this.element.addEventListener("focusout", this.onBlur);
    document.addEventListener("keydown", this.onKey);
    // A fixed bubble does not travel with the thing it points at, so it is re-placed rather than
    // dropped: moving keyboard focus to a control below the fold *scrolls*, and hiding on scroll
    // meant the one case that most needs a name -- reaching a control by keyboard -- got nothing.
    window.addEventListener("scroll", this.onScroll, true);
    window.addEventListener("resize", this.onScroll);
  }

  disconnect() {
    this.element.removeEventListener("mouseover", this.onOver);
    this.element.removeEventListener("mouseout", this.onOut);
    this.element.removeEventListener("focusin", this.onFocus);
    this.element.removeEventListener("focusout", this.onBlur);
    document.removeEventListener("keydown", this.onKey);
    window.removeEventListener("scroll", this.onScroll, true);
    window.removeEventListener("resize", this.onScroll);
    this.hide();
  }

  onOver(event) {
    const target = event.target.closest("[data-tooltip]");
    if (target) this.show(target);
  }

  onOut(event) {
    if (!event.target.closest("[data-tooltip]")) return;
    // WCAG 1.4.13 "hoverable": moving the pointer onto the bubble must not dismiss it.
    if (event.relatedTarget && event.relatedTarget.closest && event.relatedTarget.closest(".tip-bubble")) return;
    this.hide();
  }

  onFocus(event) {
    const target = event.target.closest("[data-tooltip]");
    if (target) this.show(target); else this.hide();
  }

  onBlur(event) {
    if (event.target.closest("[data-tooltip]")) this.hide();
  }

  // WCAG 1.4.13 "dismissible": without moving the pointer.
  onKey(event) {
    if (event.key === "Escape" && this.bubble) this.hide();
  }

  onScroll() {
    if (!this.bubble || !this.anchor) return;
    if (!this.anchor.isConnected) return this.hide();
    this.place(this.anchor);
  }

  show(target) {
    const text = target.dataset.tooltip;
    if (!text || this.anchor === target) return;
    this.hide();

    this.anchor = target;
    this.bubble = document.createElement("div");
    this.bubble.className = "tip-bubble";
    this.bubble.setAttribute("aria-hidden", "true");
    this.bubble.textContent = text;
    document.body.appendChild(this.bubble);
    this.place(target);
  }

  place(target) {
    const anchor = target.getBoundingClientRect();
    const bubble = this.bubble.getBoundingClientRect();
    const gap = 8;

    let left = anchor.left + anchor.width / 2 - bubble.width / 2;
    let top = anchor.bottom + gap;

    // Flip to the left of the control rather than run off the window: these sit in a column frozen
    // to the right edge, so there is frequently nothing to the right of them.
    if (left + bubble.width > window.innerWidth - gap) {
      left = anchor.left - bubble.width - gap;
      top = anchor.top + anchor.height / 2 - bubble.height / 2;
    }
    // And above rather than below when there is no room under it.
    if (top + bubble.height > window.innerHeight - gap) {
      top = anchor.top - bubble.height - gap;
    }

    this.bubble.style.left = `${Math.max(gap, left)}px`;
    this.bubble.style.top = `${Math.max(gap, top)}px`;
  }

  hide() {
    if (this.bubble) this.bubble.remove();
    this.bubble = null;
    this.anchor = null;
  }
}
