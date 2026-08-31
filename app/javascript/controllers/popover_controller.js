import { Controller } from "@hotwired/stimulus"

// An anchored floating panel: the account menu, the date range picker, anything that hangs off a
// trigger rather than covering the page.
//
// A modal is a <dialog>; this is not, because a popover must not trap focus or block the page --
// you are meant to be able to see what you are filtering while you filter it. What it does share
// with a dialog is the rest of the contract, and each part of it is the reason a hand-rolled
// version usually feels wrong:
//
//   - Escape closes it, and focus goes back to the trigger, so the keyboard does not end up
//     somewhere the user cannot see.
//   - A click outside closes it. A click inside does not, or choosing two dates would be
//     impossible.
//   - aria-expanded on the trigger says which state it is in, and the panel is only in the
//     accessibility tree while it is open, because `hidden` takes it out.
//   - It flips above the trigger when there is not room below, and shifts left when it would
//     leave the viewport. Measured against the viewport rather than positioned with CSS anchor
//     positioning, which is still Chrome-only.
export default class extends Controller {
  static targets = ["trigger", "panel"]

  // `fixed` takes the panel out of the flow entirely, for a trigger inside a scroll container.
  // A row action menu lives in a `.table-scroll`, whose `overflow-x: auto` forces `overflow-y` to
  // compute to `auto` as well -- so an absolutely positioned panel is clipped by the region on
  // both axes, and the menu on the last row was cut off at the bottom of the table. Absolute is
  // still the default: the account menu and the date range picker have no clipping ancestor, and
  // a fixed panel has to be repositioned on every scroll rather than moving with the page.
  static values = { fixed: Boolean }

  connect() {
    this.onDocumentClick = this.closeOnOutsideClick.bind(this)
    this.onKeydown = this.closeOnEscape.bind(this)
    this.onReposition = () => { if (this.isOpen) this.position() }

    this.onPanelKeydown = this.moveWithArrows.bind(this)

    document.addEventListener("click", this.onDocumentClick)
    document.addEventListener("keydown", this.onKeydown)
    this.panelTarget.addEventListener("keydown", this.onPanelKeydown)
    window.addEventListener("resize", this.onReposition)
    window.addEventListener("scroll", this.onReposition, true)
  }

  disconnect() {
    document.removeEventListener("click", this.onDocumentClick)
    document.removeEventListener("keydown", this.onKeydown)
    this.panel.removeEventListener("keydown", this.onPanelKeydown)
    window.removeEventListener("resize", this.onReposition)
    window.removeEventListener("scroll", this.onReposition, true)
    // Turbo can replace the row while the menu is open; the panel would otherwise be left on the
    // body with nothing pointing at it.
    if (this.panelHome) this.portalled.remove()
    this.panelHome = null
    this.portalled = null
  }

  // Arrow keys, Home and End move between items -- but only in a panel that calls itself a
  // `menu`. The ARIA menu pattern requires this, and the account menu had claimed `role="menu"`
  // since it was built without ever implementing it: a promise in an attribute that nothing kept.
  // The overlay audit found it the moment row action menus multiplied it by 62.
  //
  // Gated on the role, because the date range panel holds date inputs and an arrow key there
  // belongs to the input -- hijacking it would break adjusting a date with the keyboard.
  moveWithArrows(event) {
    if (this.panel.getAttribute("role") !== "menu") return
    if (!["ArrowDown", "ArrowUp", "Home", "End"].includes(event.key)) return

    const items = this.focusableItems()
    if (items.length === 0) return
    event.preventDefault()

    const here = items.indexOf(document.activeElement)
    const next = {
      ArrowDown: here < 0 ? 0 : (here + 1) % items.length,
      ArrowUp: here < 0 ? items.length - 1 : (here - 1 + items.length) % items.length,
      Home: 0,
      End: items.length - 1
    }[event.key]

    items[next].focus()
  }

  focusableItems() {
    return [...this.panel.querySelectorAll(
      "a[href], button:not([disabled]), [tabindex]:not([tabindex='-1'])"
    )].filter((el) => el.offsetParent !== null)
  }

  /*
   * A Stimulus target is looked up inside the controller's own element, so once the panel is moved
   * to `<body>` the lookup finds nothing -- "Missing target element" on the very next click. The
   * portalled node is held directly, and this is what everything else uses.
   */
  get panel() {
    return this.portalled || this.panelTarget
  }

  get isOpen() {
    return !this.panel.hidden
  }

  toggle(event) {
    event.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.portalOut()
    this.panel.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.position()

    const first = this.panel.querySelector(
      "input:not([type=hidden]), select, textarea, button, [href], [tabindex]:not([tabindex='-1'])"
    )
    first?.focus()
  }

  close({ refocus = true } = {}) {
    if (!this.isOpen) return

    this.panel.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "false")
    if (refocus) this.triggerTarget.focus()
    this.portalBack()
    // Announced, so a panel whose contents are applied *on close* has one place to listen rather
    // than three. It closes from the trigger, from Escape and from a click outside, and a control
    // that only handled the button would silently drop the other two.
    this.element.dispatchEvent(new CustomEvent("popover:close", { bubbles: true }))
  }

  /*
   * A `fixed` panel is moved to `<body>` while it is open, and put back when it closes.
   *
   * `position: fixed` escapes an ancestor's *overflow*, which is what `fixedValue` was added for --
   * but it does not escape an ancestor's **stacking context**, and the row action menu now sits
   * inside a `.cell-actions` cell that is `position: sticky` so the actions column can be frozen to
   * the right edge. Trapped there, the panel's `z-30` was resolved below the scroll rail's
   * `z-index: 20`: measured in the test environment, the rail spanned y=417-441, the *Deactivate*
   * item's centre was y=423, and `elementFromPoint` returned `.table-rail-track`. Cuprite reported
   * it honestly as "another element ... at this position" and the click never reached the menu.
   *
   * This is the same move `table_scroll_controller` already makes for the rail itself, for the
   * same class of reason: the only reliable escape from an ancestor you do not control is not to
   * be inside it. A placeholder holds the panel's place so it returns to exactly where it was,
   * which matters because Turbo may replace the row while the menu is shut.
   */
  portalOut() {
    if (!this.fixedValue || this.panelHome) return

    const panel = this.panelTarget
    this.panelHome = document.createComment("popover panel")
    panel.replaceWith(this.panelHome)
    document.body.appendChild(panel)
    this.portalled = panel
  }

  portalBack() {
    if (!this.panelHome) return

    this.panelHome.replaceWith(this.portalled)
    this.panelHome = null
    this.portalled = null
  }

  closeOnOutsideClick(event) {
    // `this.element` no longer contains the panel while it is portalled, so it is checked too --
    // otherwise the first click *inside* an open menu reads as a click outside it.
    if (!this.isOpen || this.element.contains(event.target) ||
        this.panel.contains(event.target)) return

    // No refocus: the click has already put focus where the user meant it to go, and pulling it
    // back to the trigger would undo that.
    this.close({ refocus: false })
  }

  closeOnEscape(event) {
    if (event.key !== "Escape" || !this.isOpen) return

    event.stopPropagation()
    this.close()
  }

  // Below the trigger by default; above it when the panel would run past the bottom of the
  // viewport and there is more room above. Horizontally it is left-aligned with the trigger and
  // pulled back only as far as it needs to stay on screen.
  position() {
    const panel = this.panel
    panel.style.top = panel.style.bottom = panel.style.left = panel.style.right = ""
    panel.style.maxHeight = panel.style.overflowY = ""

    const trigger = this.triggerTarget.getBoundingClientRect()
    const height = panel.offsetHeight
    const below = window.innerHeight - trigger.bottom
    const above = trigger.top

    const placeAbove = below < height + 8 && above > below

    if (this.fixedValue) {
      // Placed against the viewport, so no ancestor's overflow can clip it. Right-aligned to the
      // trigger, then pulled back if that would leave the screen.
      panel.style.position = "fixed"
      panel.style.top = placeAbove ? `${trigger.top - height - 4}px` : `${trigger.bottom + 4}px`
      const width = panel.offsetWidth
      panel.style.left = `${Math.max(8, Math.min(trigger.right - width, window.innerWidth - width - 8))}px`
      const room = (placeAbove ? above : below) - 12
      if (height > room) {
        panel.style.maxHeight = `${Math.max(room, 180)}px`
        panel.style.overflowY = "auto"
      }
      return
    }

    panel.style[placeAbove ? "bottom" : "top"] = `${this.triggerTarget.offsetHeight + 4}px`

    // Neither side may be big enough -- on a 640px-tall phone the date range panel is 466px and
    // has about 300px either way, so flipping does not help and it ran 143px off the bottom.
    // Cap it to the room there is and let it scroll, which is what Stripe and Material both do
    // before falling back to a full-screen sheet.
    const room = (placeAbove ? above : below) - 12
    if (height > room) {
      panel.style.maxHeight = `${Math.max(room, 180)}px`
      panel.style.overflowY = "auto"
    }

    const overflowRight = trigger.left + panel.offsetWidth - (window.innerWidth - 16)
    if (overflowRight > 0) panel.style.left = `${-Math.min(overflowRight, trigger.left - 16)}px`
  }
}
