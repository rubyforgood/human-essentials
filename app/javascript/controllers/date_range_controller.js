import { Controller } from "@hotwired/stimulus"

// The date range filter, inside a popover.
//
// Its job is to keep two hidden fields correct. The server still receives a single
// filters[date_range] string -- "June 19, 2026 - September 19, 2026" -- which DateRangeHelper
// splits on " - " and parses with strptime, plus filters[date_range_label] naming the preset.
// Everything visible exists to compose those two.
//
// The preset dates are computed by the server and handed over in presetsValue, so this file does
// no date arithmetic. The ranges have to agree with the Time.zone the query is filtered in, and
// the browser's midnight is not necessarily that.
//
// Opening and closing the panel belongs to the popover controller on the same element. This one
// only asks it to close, after a choice has been made.
export default class extends Controller {
  static targets = ["summary", "start", "end", "error", "apply", "presetField", "range"]
  static values = { presets: Object }

  choosePreset(event) {
    const name = event.currentTarget.dataset.preset
    const [from, to] = this.presetsValue[name]

    this.startTarget.value = from
    this.endTarget.value = to
    this.commit(name, from, to)
  }

  // Applied on a button rather than on each field's change, so setting From and then To costs one
  // request instead of two -- the inline version fired an intermediate query for a range nobody
  // asked for.
  applyCustom() {
    if (!this.validate()) return

    this.commit("Custom", this.startTarget.value, this.endTarget.value)
  }

  validate() {
    const { value: from } = this.startTarget
    const { value: to } = this.endTarget
    // ISO dates sort lexically, so this needs no parsing.
    const backwards = Boolean(from && to && to < from)

    this.errorTarget.hidden = !backwards
    this.endTarget.setCustomValidity(backwards ? "The end date must be on or after the start date." : "")

    return Boolean(from) && Boolean(to) && !backwards
  }

  commit(name, from, to) {
    this.presetFieldTarget.value = name
    this.rangeTarget.value = `${this.humanize(from)} - ${this.humanize(to)}`
    this.summaryTarget.querySelector("span").textContent =
      name === "Custom" ? `${this.humanize(from)} to ${this.humanize(to)}` : name

    this.dispatchChange()
    this.popover?.close()
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
  humanize(iso) {
    const [year, month, day] = iso.split("-").map(Number)
    return new Date(year, month - 1, day).toLocaleDateString("en-US", {
      month: "long",
      day: "numeric",
      year: "numeric",
    })
  }
}
