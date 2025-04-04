import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
	static targets = ["source", "destination"]
	static values = {
		valuesToHide: Array
	}
	sourceChanged() {
		const val = $(this.sourceTarget).val()
		this.destinationTargets.forEach(
			destination_target => { $(destination_target).toggleClass("d-none", this.valuesToHideValue.includes(val)); }
		)
	}
}
