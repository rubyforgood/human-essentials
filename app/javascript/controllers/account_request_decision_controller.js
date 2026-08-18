import { Controller } from "@hotwired/stimulus"

/*
 * The reject / close decision on an account request.
 *
 * Both decisions post the same two fields to different endpoints, so one dialog serves the
 * whole table: the trigger says which decision it is and which request it applies to, and
 * this points the form at the matching action before opening.
 *
 * It replaces a jQuery block that called $("#reject-modal").modal("show") -- Bootstrap's
 * modal, which is not loaded any more, so the button did nothing at all -- and that
 * hand-rolled the "a reason is required" check by unhiding an <a>. The textarea is
 * `required`, so the browser enforces it and says so on the field itself.
 */
export default class extends Controller {
  static targets = ["dialog", "form", "id", "title", "reason", "submitLabel", "error"]
  static values = { rejectUrl: String, closeUrl: String }

  open(event) {
    event.preventDefault()
    const { id, decision, organization } = event.params
    const closing = decision === "close"

    this.formTarget.action = closing ? this.closeUrlValue : this.rejectUrlValue
    this.idTarget.value = id
    this.titleTarget.textContent = closing ? "Close account request" : "Reject account request"
    this.submitLabelTarget.textContent = closing ? "Close request" : "Reject request"
    this.reasonTarget.value = ""
    this.hideError()
    this.reasonTarget.labels[0].textContent = closing
      ? `Why are you closing ${organization}'s request?`
      : `Why are you rejecting ${organization}'s request?`

    this.opener = event.currentTarget
    this.dialogTarget.showModal()
    this.reasonTarget.focus()
  }

  // A blank reason is not a decision anyone can act on, and a reason of one space is blank.
  // HTML5 `required` counts a space as filled, so the check is here and the message is a real
  // element rather than a browser bubble nothing else can read.
  validate(event) {
    if (this.reasonTarget.value.trim() !== "") {
      this.hideError()
      return
    }

    event.preventDefault()
    this.errorTarget.classList.remove("hidden")
    this.reasonTarget.setAttribute("aria-invalid", "true")
    this.reasonTarget.focus()
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
    this.reasonTarget.removeAttribute("aria-invalid")
  }

  // A click that lands on the <dialog> itself is a click on its backdrop: anything inside
  // is a child element and stops there first.
  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) event.currentTarget.close()
  }

  close() {
    this.dialogTarget.close()
  }

  restoreFocus() {
    this.opener?.focus()
  }
}
