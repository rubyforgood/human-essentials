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
      // `hidden`, not Bootstrap's `d-none`, which ADR 0011 left defined nowhere -- it appears 0
      // times in the compiled stylesheet, so the class would be added and removed and nothing
      // would ever hide. This arrived from main as `d-none`; migration-map.md records four earlier
      // controllers with the identical fault, where partner-group reminder fields, the shipping
      // cost and the admin role picker could never be revealed. This was the fifth.
      field.classList.toggle("hidden", !show)
    })
  }
}
