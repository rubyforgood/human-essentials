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
    this.frame = document.getElementById(this.element.dataset.turboFrame || "")
    if (!this.frame) return

    this.onFrameLoad = () => {
      this.announce()
      this.syncExports()

      // Only for a load this controller caused. turbo:frame-load also fires when the frame is
      // first connected, on every ordinary page load -- clearing the flash there would delete
      // the message the page was rendered to show.
      if (this.applying) this.clearFlash()
      this.applying = false
    }
    this.frame.addEventListener("turbo:frame-load", this.onFrameLoad)
  }

  disconnect() {
    clearTimeout(this.timer)
    this.frame?.removeEventListener("turbo:frame-load", this.onFrameLoad)
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

  // Applying a filter used to be a page load, which cleared the flash with it. Into a frame it
  // does not, so "Storage location deactivated successfully" would sit above a table it no longer
  // describes -- and keep sitting there through every subsequent filter.
  clearFlash() {
    document.querySelector("turbo-frame#flash")?.replaceChildren()
  }

  summary() {
    // A page with a summary card has already worked out the total, in a sentence.
    const scope = this.frame.querySelector("[data-filter-scope]")
    if (scope) return scope.textContent.trim()

    // Otherwise count the rows -- but only when they are all of them. On a paginated page the
    // rows on screen are not the total, and announcing "51 results" when 51 is merely the page
    // size would be worse than saying nothing precise.
    if (this.frame.querySelector("nav[aria-label='Pagination']")) return "Results updated"

    const rows = this.frame.querySelectorAll("table.data-table tbody tr").length
    return `${rows} ${rows === 1 ? "result" : "results"}`
  }

  // Selects, checkboxes and date inputs: apply straight away. Typeable fields are skipped here
  // and handled by debounce(), or every committed keystroke would submit twice -- once on input
  // and again on the change that fires at blur.
  submit(event) {
    if (this.typeable(event?.target)) return

    clearTimeout(this.timer)
    this.applying = true
    this.element.requestSubmit()
  }

  // Typing: wait for a pause. requestSubmit rather than submit() so the form's validation still
  // runs -- the date range controller relies on it to block an end-before-start range.
  debounce(event) {
    if (!this.typeable(event?.target)) return

    clearTimeout(this.timer)
    this.timer = setTimeout(() => {
      this.applying = true
      this.element.requestSubmit()
    }, this.delayValue)
  }

  typeable(target) {
    if (!target) return false
    if (target.tagName === "TEXTAREA") return true
    return target.tagName === "INPUT" &&
      ["text", "search", "email", "tel", "url", "number", "password"].includes(target.type)
  }
}
