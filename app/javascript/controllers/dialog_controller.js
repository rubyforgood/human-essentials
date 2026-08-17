import { Controller } from "@hotwired/stimulus"

/*
 * A native <dialog>.
 *
 * showModal() gives us the focus trap, the Escape handler, inert background content and the
 * top layer for free -- all things the Bootstrap modal reimplemented in JS and got partly
 * wrong. The only things left to add are closing on a backdrop click and restoring focus to
 * whatever opened it.
 *
 * A trigger names its dialog so one controller instance can drive several on a page:
 *
 *   <button data-action="click->dialog#open" data-dialog-id-param="csv-import-modal">
 *
 * With no param it falls back to the single dialogTarget in scope.
 */
export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    event?.preventDefault()
    this.opener = event?.currentTarget
    this.dialogFor(event)?.showModal()
  }

  close(event) {
    event?.preventDefault()
    this.dialogFor(event)?.close()
  }

  // A click that lands on the <dialog> element itself is a click on its backdrop: anything
  // inside is a child element and stops there first.
  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) event.currentTarget.close()
  }

  restoreFocus() {
    this.opener?.focus()
  }

  dialogFor(event) {
    const id = event?.params?.id || event?.currentTarget?.dataset?.dialogIdParam
    if (id) return document.getElementById(id)
    if (this.hasDialogTarget) return this.dialogTarget
    return event?.currentTarget?.closest("dialog")
  }
}
