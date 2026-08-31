import { Controller } from "@hotwired/stimulus"

// The month range filter, inside a popover. A sibling of date_range_controller, and smaller,
// because a month needs no locale formatting: the wire format is two ISO months, "2025-09 -
// 2026-08", which cannot be read in two orders and so needs no conversion.
//
// Its job is to keep one hidden field correct and then submit. The preset values are computed by
// the server and handed over in presetsValue, so this file does no date arithmetic -- the ranges
// have to agree with the Time.zone the query is filtered in, and the browser's midnight is not
// necessarily that.
//
// Opening and closing the panel belongs to the popover controller on the same element.
export default class extends Controller {
  static targets = ["summary", "start", "end", "range"]
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

  // Custom months apply themselves, on the same terms as the date filter: no Apply button, the
  // panel stays open so the range can be adjusted, and a debounce so From-then-To is one request
  // rather than two.
  changeCustom(event) {
    event?.stopPropagation()
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.applyCustom(), 350)
  }

  applyCustom() {
    this.sort()
    const from = this.startTarget.value
    const to = this.endTarget.value
    if (!from || !to) return
    this.commit(null, from, to)
  }

  // Out of order is a range entered back to front, not an error. ISO months sort lexically, so
  // this needs no parsing at all.
  sort() {
    const { value: from } = this.startTarget
    const { value: to } = this.endTarget
    if (!from || !to || from <= to) return
    this.startTarget.value = to
    this.endTarget.value = from
  }

  // The controller element *is* the form -- see the partial. A target has to be a descendant of
  // its controller, and putting month-range on a div inside the form made this.formTarget throw
  // "Missing target element" on every preset press.
  commit(presetName, from, to) {
    this.rangeTarget.value = `${from} - ${to}`
    this.summaryTarget.querySelector("span").textContent = presetName || `${this.label(from)} – ${this.label(to)}`
    this.element.requestSubmit()
  }

  // "2025-09" -> "Sep 2025". Built from the parts rather than new Date(iso), which reads a bare
  // ISO value as UTC and lands in the previous month for anyone west of Greenwich.
  label(iso) {
    const [year, month] = iso.split("-").map(Number)
    return new Date(year, month - 1, 1).toLocaleDateString("en-US", { month: "short", year: "numeric" })
  }

  get popover() {
    return this.application.getControllerForElementAndIdentifier(this.element, "popover")
  }
}
