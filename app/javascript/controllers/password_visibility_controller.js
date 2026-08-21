import { Controller } from "@hotwired/stimulus";

/*
 * Show/hide the password field.
 *
 * The glyphs are Bootstrap Icons, because that is what the markup uses. This toggled `fa-eye`
 * and `fa-eye-slash` -- Font Awesome, which the design system migration removed -- so the icon
 * never changed and the button quietly accumulated two classes that style nothing.
 *
 * The accessible name has to change with the state as well: a button that always says "Show
 * password" is wrong half the time, and the glyph is aria-hidden so it says nothing at all.
 */
export default class extends Controller {
  static targets = ["password", "icon"];

  toggle(event) {
    const willShow = this.passwordTarget.type === "password";

    this.passwordTarget.type = willShow ? "text" : "password";
    this.iconTarget.classList.toggle("bi-eye", willShow);
    this.iconTarget.classList.toggle("bi-eye-slash", !willShow);
    event.currentTarget.setAttribute("aria-label", willShow ? "Hide password" : "Show password");
  }
}
