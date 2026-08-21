import { Controller } from "@hotwired/stimulus"

// Applies a filter bar as soon as a control changes, so there is no Filter button to press.
//
// Whether that is a good idea depends entirely on what a submit costs. Turbo Drive is off in
// this app (application.js), so a plain submit reloads the whole document and throws away scroll
// position and focus -- which is why the busy pages used to keep the button. Bars that pass
// `frame:` submit into a Turbo Frame instead: the results are replaced in place, and applying on
// every change is cheap enough to be the obvious behaviour.
//
// The Filter button is hidden in the markup, not from here. Hiding it on connect meant the
// browser painted it and then took it away a frame later, which flashed on every page load. A
// <noscript> rule in the partial brings it back when this controller cannot run.
export default class extends Controller {
  static targets = ["status"]
  static values = { delay: { type: Number, default: 400 } }

  connect() {
    this.frameId = this.element.dataset.turboFrame
    if (!this.frameId) return

    // Listened for on the document, and the frame looked up when it is needed rather than here.
    // The form is parsed before the frame it targets, so resolving the element at connect time
    // could return null -- and then the export link and the announcement silently stopped
    // working, with nothing on screen to say so. It held in a browser and not under Cuprite,
    // which is the kind of difference that hides a real bug in a timing story.
    this.onFrameLoad = (event) => {
      if (event.target.id !== this.frameId) return

      this.announce()
      this.syncExports()
    }
    document.addEventListener("turbo:frame-load", this.onFrameLoad)
  }

  disconnect() {
    clearTimeout(this.timer)
    document.removeEventListener("turbo:frame-load", this.onFrameLoad)
  }

  get frame() {
    return document.getElementById(this.frameId)
  }

  // A filter applying into a frame is silent: nothing navigates and focus does not move, so a
  // screen reader is told nothing at all. The results already carry a sentence describing what
  // is now on screen -- copy it into the live region, which lives outside the frame because an
  // aria-live element that is itself replaced does not announce its new contents.
  announce() {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = this.summary()
  }

  // The Export link is in the page header, outside the frame, so applying a filter in place
  // leaves it pointing at the query from before. Exporting the wrong rows is a worse failure
  // than a stale table: the file is correct-looking and nothing on screen says otherwise.
  //
  // Rebuilt from the form itself, which is the live filter state, keeping the link's own path so
  // the `.csv` format stays put.
  syncExports() {
    const params = new URLSearchParams()
    for (const [name, value] of new FormData(this.element)) params.append(name, value)

    document.querySelectorAll("[data-filter-export]").forEach((link) => {
      const url = new URL(link.getAttribute("href"), window.location.origin)
      link.setAttribute("href", `${url.pathname}?${params}`)
    })
  }

  // No clearing of the flash here, and that is deliberate. A filter used to be a page load, which
  // took the flash with it, so restoring that seemed right -- but removing 56px from above the
  // results moves everything below it, under a cursor that is often already over a row action.
  // A layout shift in response to an unrelated action is a hazard for a person and it broke three
  // specs that click a row action after filtering. A message about something that did happen is
  // the cheaper problem; it clears on the next real navigation.

  summary() {
    // A page with a summary card has already worked out the total, in a sentence.
    const scope = this.frame.querySelector("[data-filter-scope]")
    if (scope) return scope.textContent.trim()

    // A paginated table states its own total, and that sentence is better than a row count:
    // the rows on screen are one page of them. This used to return the literal "Results
    // updated", because the pager only appeared when there were two pages and there was
    // nothing on a single-page table to read.
    const pager = this.frame.querySelector("[data-pagination-summary]")
    if (pager) return pager.textContent.replace(/\s+/g, " ").trim()

    const rows = this.frame.querySelectorAll("table.data-table tbody tr").length
    return `${rows} ${rows === 1 ? "result" : "results"}`
  }

  // Selects, checkboxes and date inputs: apply straight away. Typeable fields are skipped here
  // and handled by debounce(), or every committed keystroke would submit twice -- once on input
  // and again on the change that fires at blur.
  submit(event) {
    if (this.typeable(event?.target)) return

    clearTimeout(this.timer)
    this.element.requestSubmit()
  }

  // Typing: wait for a pause. requestSubmit rather than submit() so the form's validation still
  // runs -- the date range controller relies on it to block an end-before-start range.
  debounce(event) {
    if (!this.typeable(event?.target)) return

    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  typeable(target) {
    if (!target) return false
    if (target.tagName === "TEXTAREA") return true
    return target.tagName === "INPUT" &&
      ["text", "search", "email", "tel", "url", "number", "password"].includes(target.type)
  }
}
