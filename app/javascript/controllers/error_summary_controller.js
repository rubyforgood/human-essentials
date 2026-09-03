import { Controller } from "@hotwired/stimulus";

/*
 * Moves focus to the validation error summary when a form comes back failed.
 *
 * A failed submit re-renders the whole page here -- Turbo Drive is off app-wide -- so the browser
 * puts focus on `<body>` and the user is at the top of a document that looks much like the one they
 * just sent. Measured on `/manufacturers`, `/vendors` and `/storage_locations`: after the failure
 * `document.activeElement` was `BODY` on all three, and `window.scrollY` was 0 whether or not the
 * summary was on screen.
 *
 * WHY `role="alert"` IS NOT ENOUGH ON ITS OWN. A live region is defined in terms of *change*: the
 * assistive technology watches a subtree and speaks what appears in it. On a full page load the
 * summary is already in the markup when the accessibility tree is first built, so nothing has
 * changed and support for announcing it varies between screen readers. Focus does not depend on
 * timing in that way -- and it also puts a keyboard user at the errors instead of at the top of
 * the page, which the live region alone never does.
 *
 * THE LIVE REGION MOVED INSIDE, and the container takes focus. Focusing an element that is itself
 * `role="alert"` is the combination that reads the same content twice on several screen
 * reader and browser pairings -- once because the region changed, once because focus entered it.
 * Wrapping the contents in the live region and focusing the wrapper is the shape the GOV.UK error
 * summary settled on for exactly this reason. Worth being plain about the limit: what is verified
 * here is the mechanics -- focus lands on the summary and the page scrolls to it -- because no
 * screen reader can be driven from this environment. The announcement behaviour follows the
 * published pattern rather than a measurement taken in this repository.
 *
 * IT TAKES FOCUS ONLY FROM NOTHING. On the full page load this is written for, `activeElement` is
 * `<body>`, so there is nothing to interrupt. If the summary ever arrives in a frame update while
 * somebody is typing in a field further down, stealing the caret would be hostile and would lose
 * their place -- so the guard leaves focus exactly where it is.
 */
export default class extends Controller {
  connect() {
    const active = document.activeElement;
    const idle = !active || active === document.body || active === document.documentElement;
    if (!idle) return;

    // `focus()` scrolls the element into view, which is wanted: on a long form the summary is
    // often above the fold only by accident.
    this.element.focus();
  }
}
