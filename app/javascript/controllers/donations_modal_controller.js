import { Controller } from "@hotwired/stimulus"

/*
 * "Add a new one" from inside a select.
 *
 * Choosing the "new" option loads a form into the `modal-new` Turbo frame; when the frame
 * renders we open it, and when its submission succeeds we close it.
 *
 * Uses the native <dialog> rather than bootstrap.Modal: Bootstrap's modal CSS is not loaded
 * on design system pages, so bootstrap.Modal.show() would toggle classes that style nothing
 * and the form would appear inline with no backdrop, no focus trap and no Escape handling.
 */
export default class extends Controller {
  connect() {
    document.addEventListener("turbo:frame-render", this.openModalHandler)
    document.addEventListener("turbo:submit-end", this.closeModalHandler)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-render", this.openModalHandler)
    document.removeEventListener("turbo:submit-end", this.closeModalHandler)
  }

  handleNewSelect(event) {
    if (event.target.value !== "new") return
    Turbo.visit(event.target.dataset.url, { frame: "modal-new" })
  }

  // The frame's contents are replaced on each render, so find the dialog fresh each time.
  dialog() {
    return document.querySelector("#modal-new dialog")
  }

  openModalHandler = () => {
    const dialog = this.dialog()
    if (dialog && !dialog.open) dialog.showModal()
  }

  closeModalHandler = (event) => {
    if (!event.detail.success) return
    const dialog = this.dialog()
    if (dialog?.open) dialog.close()
  }
}
