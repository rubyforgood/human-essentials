import { Controller } from "@hotwired/stimulus"

// Replaces `window.confirm` with the app's own dialog.
//
// Every destructive row action carries `data-confirm`, which rails-ujs turns into a native
// `window.confirm` -- browser chrome, unstyled, unbranded, and it announces the page's hostname
// above the message. 44 call sites did that.
//
// **Why this intercepts the click rather than overriding `Rails.confirm`.** rails-ujs's confirm
// hook is synchronous: it must return true or false there and then. A `<dialog>` is asynchronous --
// it resolves when someone presses a button. There is no way to answer synchronously from one, so
// the click is caught in the *capture* phase before rails-ujs sees it, and replayed afterwards if
// the answer was yes.
//
// `stopImmediatePropagation` is the important part: rails-ujs binds on `document`, so merely
// preventing the default is not enough -- its handler would still run and raise its own confirm.
//
// The replay removes `data-confirm` from the element first and restores it afterwards, so neither
// this handler nor rails-ujs acts on the replayed click, and the next click asks again.
export default class extends Controller {
  static targets = ["dialog", "message", "accept", "title"]

  connect() {
    this.onClick = this.intercept.bind(this)
    document.addEventListener("click", this.onClick, true)

    // A promise API for the one place that cannot go through `data-confirm`: `utils/donations.js`
    // guards a large donation from inside its own click handler. Anything else needing a
    // confirmation should use `data-confirm` and never touch this.
    window.essentialsConfirm = (options) => this.ask(options)
  }

  disconnect() {
    document.removeEventListener("click", this.onClick, true)
    if (window.essentialsConfirm) delete window.essentialsConfirm
  }

  // Show the dialog and resolve true or false. The click interception below is the same thing
  // with the answer replayed as a click instead of returned.
  ask({ message, title, label, tone } = {}) {
    this.fill({ message, title, label, tone })
    this.dialogTarget.showModal()
    return new Promise((resolve) => { this.resolve = resolve })
  }

  fill({ message, title, label, tone }) {
    const danger = tone === "danger"
    this.titleTarget.textContent = title || "Are you sure?"
    this.messageTarget.textContent = message
    this.acceptTarget.textContent = label || (danger ? "Delete" : "Continue")
    this.acceptTarget.className = danger ? this.dangerClasses : this.primaryClasses
  }

  intercept(event) {
    const trigger = event.target.closest("[data-confirm], [data-turbo-confirm]")
    if (!trigger || !this.hasDialogTarget) return
    event.preventDefault()
    event.stopImmediatePropagation()

    this.pending = trigger

    // A destructive action gets a red confirm button and its own verb. The tone is opt-in via
    // `data-confirm-tone`, which the row action helper sets from the item's tone, so a call site
    // cannot put a red button on a harmless action.
    this.fill({
      message: trigger.dataset.confirm || trigger.dataset.turboConfirm,
      title: trigger.dataset.confirmTitle,
      label: trigger.dataset.confirmLabel,
      tone: trigger.dataset.confirmTone
    })
    this.dialogTarget.showModal()
  }

  get primaryClasses() {
    return this.acceptTarget.dataset.primaryClass
  }

  get dangerClasses() {
    return this.acceptTarget.dataset.dangerClass
  }

  accept() {
    const trigger = this.pending
    this.dialogTarget.close()
    if (this.resolve) { this.resolve(true); this.resolve = null; return }
    if (!trigger) return

    // Replay the click that was swallowed -- with `data-confirm` taken *off* the element first.
    //
    // Marking it as already-confirmed is not enough: this handler would pass it through and then
    // rails-ujs, which is still bound on `document` and still sees the attribute, would raise its
    // own native confirm on the way past. The attribute has to be gone for the replay and back
    // afterwards, so the next click asks again.
    const attr = trigger.hasAttribute("data-confirm") ? "data-confirm" : "data-turbo-confirm"
    const message = trigger.getAttribute(attr)
    trigger.removeAttribute(attr)
    trigger.click()
    trigger.setAttribute(attr, message)

    this.pending = null
  }

  cancel() {
    this.dialogTarget.close()
    if (this.resolve) { this.resolve(false); this.resolve = null }
    this.pending = null
  }
}
