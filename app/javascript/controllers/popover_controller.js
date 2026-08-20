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

  connect() {
    this.onDocumentClick = this.closeOnOutsideClick.bind(this)
    this.onKeydown = this.closeOnEscape.bind(this)
    this.onReposition = () => { if (this.isOpen) this.position() }

    document.addEventListener("click", this.onDocumentClick)
    document.addEventListener("keydown", this.onKeydown)
    window.addEventListener("resize", this.onReposition)
    window.addEventListener("scroll", this.onReposition, true)
  }

  disconnect() {
    document.removeEventListener("click", this.onDocumentClick)
    document.removeEventListener("keydown", this.onKeydown)
    window.removeEventListener("resize", this.onReposition)
    window.removeEventListener("scroll", this.onReposition, true)
  }

  get isOpen() {
    return !this.panelTarget.hidden
  }

  toggle(event) {
    event.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    this.panelTarget.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.position()

    const first = this.panelTarget.querySelector(
      "input:not([type=hidden]), select, textarea, button, [href], [tabindex]:not([tabindex='-1'])"
    )
    first?.focus()
  }

  close({ refocus = true } = {}) {
    if (!this.isOpen) return

    this.panelTarget.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "false")
    if (refocus) this.triggerTarget.focus()
  }

  closeOnOutsideClick(event) {
    if (!this.isOpen || this.element.contains(event.target)) return

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
    const panel = this.panelTarget
    panel.style.top = panel.style.bottom = panel.style.left = ""

    const trigger = this.triggerTarget.getBoundingClientRect()
    const height = panel.offsetHeight
    const below = window.innerHeight - trigger.bottom

    if (below < height + 8 && trigger.top > below) {
      panel.style.bottom = `${this.triggerTarget.offsetHeight + 4}px`
    } else {
      panel.style.top = `${this.triggerTarget.offsetHeight + 4}px`
    }

    const overflowRight = trigger.left + panel.offsetWidth - (window.innerWidth - 16)
    if (overflowRight > 0) panel.style.left = `${-Math.min(overflowRight, trigger.left - 16)}px`
  }
}
