import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
		static targets = ["source", "destination"]

		sourceChanged() {
				const val = $(this.sourceTarget).val()
				this.destinationTargets.forEach(
					destination_target => { $(destination_target).toggleClass("d-none", val == "super_admin"); }
				)
		}
}
