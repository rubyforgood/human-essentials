import { Controller } from "@hotwired/stimulus"

// Submits a filter form as soon as a control changes, for filter bars with a single filter.
//
// Industry practice splits on how many filters there are: apply immediately when there is one,
// batch behind an Apply button when there are several, because auto-applying each of five
// controls fires five queries while the user is still describing what they want. This app has
// both shapes -- four index pages filter on one thing, twelve filter on between two and nine --
// so the behaviour is opt-in per page rather than global.
//
// The Filter button is hidden in the markup, not from here. Hiding it on connect meant the
// browser painted it and then took it away a frame later, which flashed on every page load --
// and because submitting navigates, that was every selection too. A <noscript> rule in the
// partial brings it back when this controller cannot run.
export default class extends Controller {
  submit() {
    // requestSubmit fires validation and submit events; form.submit() skips both.
    this.element.requestSubmit()
  }
}
