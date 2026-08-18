import { Controller } from "@hotwired/stimulus"

// Submits a filter form as soon as a control changes, for filter bars with a single filter.
//
// Industry practice splits on how many filters there are: apply immediately when there is one,
// batch behind an Apply button when there are several, because auto-applying each of five
// controls fires five queries while the user is still describing what they want. This app has
// both shapes -- four index pages filter on one thing, twelve filter on between two and nine --
// so the behaviour is opt-in per page rather than global.
//
// The submit button is not removed from the markup, it is hidden here on connect. Without
// JavaScript the form still works the old way, which is the only reason the button can go at all.
export default class extends Controller {
  static targets = ["submit"]

  connect() {
    // display:none as an inline style, not the `hidden` utility. The button already carries
    // `inline-flex` from the button base, and two Tailwind utilities setting `display` resolve
    // by stylesheet order rather than by the order they appear in the class attribute --
    // `inline-flex` wins, and adding `hidden` does nothing at all. An inline style outranks both.
    this.submitTargets.forEach((el) => {
      el.style.display = "none"
    })
  }

  disconnect() {
    this.submitTargets.forEach((el) => {
      el.style.removeProperty("display")
    })
  }

  submit() {
    // requestSubmit fires validation and submit events; form.submit() skips both.
    this.element.requestSubmit()
  }
}
