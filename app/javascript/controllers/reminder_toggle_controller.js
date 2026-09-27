import { Controller } from "@hotwired/stimulus"

/*
 * ReminderToggleController shows/hides dependent reminder-schedule fields based
 * on the selected value of a Yes/No radio-button group. Used on the organization
 * settings form so the reminder schedule and reminder email text are only shown
 * when "Send monthly deadline reminder emails?" is set to Yes.
 */
export default class extends Controller {
  static targets = ["source", "dependentField"]

  connect() {
    this.toggle()
  }

  toggle() {
    const selected = this.sourceTargets.find((input) => input.checked)
    const show = selected?.value === "true"
    this.dependentFieldTargets.forEach((field) => {
      field.classList.toggle("d-none", !show)
    })
  }
}
