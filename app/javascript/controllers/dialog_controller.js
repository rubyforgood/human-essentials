import { Controller } from "@hotwired/stimulus"

/*
 * A native <dialog>.
 *
 * showModal() gives us the focus trap, the Escape handler, inert background content and
 * the top layer for free -- all things the Bootstrap modal reimplemented in JS and got
 * partly wrong. The only things left to add are closing on a backdrop click and restoring
 * focus to whatever opened it.
 */
export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    event?.preventDefault()
    this.opener = event?.currentTarget
    this.dialogTarget.showModal()
  }

  close(event) {
    event?.preventDefault()
    this.dialogTarget.close()
  }

  // A click that lands on the <dialog> element itself is a click on its backdrop: the
  // contents are a child element, so anything inside stops here first.
  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.dialogTarget.close()
  }

  restoreFocus() {
    this.opener?.focus()
  }
}
