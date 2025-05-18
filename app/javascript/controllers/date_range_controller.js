// This Stimulus controller is used to handle custom validation for the date range input field.
// Litepicker.js manages the date range field and prevents invalid data when users interact with its calendar control.
// However, if a user tabs into the field and enters invalid data without triggering Litepicker events,
// Litepicker won't validate the input, leaving invalid data in the field.
// This controller ensures that in such cases, custom validation is performed to alert the user about invalid input.

import { Controller } from "@hotwired/stimulus";
import { DateTime } from "luxon";

export default class extends Controller {
  static targets = ["input"];

  connect() {
    this.initialStart = this.inputTarget.dataset.initialStartDate;
    this.initialEnd = this.inputTarget.dataset.initialEndDate;
    this.format = "MMMM d, yyyy";
  }

  validate(event) {
    event.preventDefault();

    // experiment
    if (this.inputTarget.dataset.skipValidation === "true") {
      return;
    }

    if (window.isLitepickerActive) {
      return;
    }

    const value = this.inputTarget.value.trim();
    const [startStr, endStr] = value.split(" - ").map((s) => s.trim());

    const isValid = this.isValidDateRange(startStr, endStr);

    if (!isValid) {
      alert("Please enter a valid date range (e.g., January 1, 2024 - March 15, 2024).")
    }
  }

  isValidDateRange(startStr, endStr) {
    try {
      const start = DateTime.fromFormat(startStr, this.format);
      const end = DateTime.fromFormat(endStr, this.format);

      return start.isValid && end.isValid && start <= end;
    } catch (error) {
      return false;
    }
  }
}
