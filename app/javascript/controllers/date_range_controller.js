// The date range filter.
//
// Its whole job is to keep one hidden field correct. The server still receives a single
// filters[date_range] string -- "June 19, 2026 - September 19, 2026" -- which DateRangeHelper
// splits on " - " and parses with strptime. The select and the two date inputs are the user's
// way of composing that string; nothing else about the request changed.
//
// The preset dates are computed by the server and handed over in presetsValue, so this file
// does no date arithmetic at all. That is deliberate: the ranges have to agree with the
// Time.zone the query is filtered in, and the browser's midnight is not necessarily that.

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["preset", "custom", "start", "end", "range", "error"];
  static values = { presets: Object };

  connect() {
    this.sync();
  }

  // A preset fills the two date inputs, so switching to "Custom" afterwards starts from the
  // range you were just looking at rather than from nothing.
  choosePreset() {
    const preset = this.presetsValue[this.presetTarget.value];
    if (preset) {
      this.startTarget.value = preset[0];
      this.endTarget.value = preset[1];
    }
    this.sync();
  }

  // Editing either date means the range is no longer whichever preset was showing.
  chooseCustom() {
    this.presetTarget.value = "Custom";
    this.sync();
  }

  sync() {
    const custom = this.presetTarget.value === "Custom";
    this.customTarget.hidden = !custom;

    const start = this.startTarget.value;
    const end = this.endTarget.value;
    // ISO dates sort lexically, so this needs no parsing.
    const backwards = Boolean(start && end && end < start);

    this.errorTarget.hidden = !backwards;
    // setCustomValidity blocks the submit itself. The old control raised a window.alert(),
    // which the design system does not use anywhere else and which a screen reader user
    // meets with no way back to the field that caused it.
    this.endTarget.setCustomValidity(backwards ? "The end date must be on or after the start date." : "");

    if (!start || !end || backwards) return;
    this.rangeTarget.value = `${this.humanize(start)} - ${this.humanize(end)}`;
  }

  // "2026-06-19" -> "June 19, 2026", the format strptime is waiting for. Built from the parts
  // rather than new Date(iso), which reads a bare ISO date as UTC and lands on the previous
  // day for anyone west of Greenwich.
  humanize(iso) {
    const [year, month, day] = iso.split("-").map(Number);
    return new Date(year, month - 1, day).toLocaleDateString("en-US", {
      month: "long",
      day: "numeric",
      year: "numeric",
    });
  }
}
