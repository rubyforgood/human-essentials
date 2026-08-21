import { Controller } from "@hotwired/stimulus"

// The date range filter, inside a popover.
//
// Its job is to keep two hidden fields correct. The server still receives a single
// filters[date_range] string -- "June 19, 2026 - September 19, 2026" -- which DateRangeHelper
// splits on " - " and parses with strptime, plus filters[date_range_label] naming the preset.
// Everything visible exists to compose those two. The wire format is unchanged; only what the
// user reads is short.
//
// The preset dates are computed by the server and handed over in presetsValue, so this file does
// no date arithmetic. The ranges have to agree with the Time.zone the query is filtered in, and
// the browser's midnight is not necessarily that.
//
// Opening and closing the panel belongs to the popover controller on the same element. This one
// only asks it to close, after a choice has been made.
export default class extends Controller {
  static targets = ["summary", "start", "end", "presetField", "range"]
  static values = { presets: Object }

  // A preset is a complete choice, so it applies and closes the panel.
  choosePreset(event) {
    const name = event.currentTarget.dataset.preset
    const [from, to] = this.presetsValue[name]

    this.startTarget.value = from
    this.endTarget.value = to
    this.commit(name, from, to)
    this.popover?.close()
  }

  // Custom dates apply themselves. There is no Apply button: it was a second click for something
  // the user had already said, and Stripe, Shopify, Linear and Notion all commit on selection.
  // Google Analytics is the well-known exception and the one people complain about.
  //
  // Two things make that workable with two separate fields rather than a calendar:
  //
  //   The panel stays open, so the range can be adjusted without reopening it. Only a preset
  //   closes it. Picking From and then To reads as one gesture.
  //
  //   A short debounce, so From-then-To costs one request rather than two. That was the real
  //   argument for the Apply button, and it is a timing problem, not a reason to ask twice.
  changeCustom(event) {
    // The From and To fields sit inside the filter bar's form, and the bar submits on any change
    // that reaches it. Left to bubble, editing a date fired a query carrying the *previous* range
    // from the hidden field, and then a second one when the debounce committed the new one. The
    // hidden field's own change event, dispatched in commit(), is the one the bar should see.
    event?.stopPropagation()

    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.applyCustom(), 350)
  }

  applyCustom() {
    this.sort()

    const from = this.startTarget.value
    const to = this.endTarget.value
    if (!from || !to) return

    this.commit("Custom", from, to)
  }

  // Out of order is not an error, it is a range entered back to front. Google Flights, Airbnb,
  // Booking and Material's range picker all reorder rather than refuse; this used to show
  // "The end date must be on or after the start date." and do nothing until the user fixed it.
  // ISO dates sort lexically, so this needs no parsing.
  sort() {
    const { value: from } = this.startTarget
    const { value: to } = this.endTarget
    if (!from || !to || from <= to) return

    this.startTarget.value = to
    this.endTarget.value = from
  }

  commit(name, from, to) {
    this.presetFieldTarget.value = name
    this.rangeTarget.value = `${this.wire(from)} - ${this.wire(to)}`
    this.summaryTarget.querySelector("span").textContent =
      name === "Custom" ? `${this.short(from)} – ${this.short(to)}` : name

    this.dispatchChange()
  }

  get popover() {
    return this.application.getControllerForElementAndIdentifier(this.element, "popover")
  }

  // On the hidden field, so the filter bar's auto-submit and summary controllers both see it.
  dispatchChange() {
    this.rangeTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // "2026-06-19" -> "June 19, 2026", the format strptime is waiting for. Built from the parts
  // rather than new Date(iso), which reads a bare ISO date as UTC and lands on the previous day
  // for anyone west of Greenwich.
  wire(iso) {
    return this.parse(iso).toLocaleDateString("en-US", { month: "long", day: "numeric", year: "numeric" })
  }

  // "2026-06-19" -> "6/19/2026". What the trigger shows. Spelled out, a custom range read
  // "June 19, 2026 to September 19, 2026" and needed 233px in a 223px button, so the user saw it
  // cut off -- the one thing the control exists to tell them.
  short(iso) {
    return this.parse(iso).toLocaleDateString("en-US", { month: "numeric", day: "numeric", year: "numeric" })
  }

  parse(iso) {
    const [year, month, day] = iso.split("-").map(Number)
    return new Date(year, month - 1, day)
  }
}
