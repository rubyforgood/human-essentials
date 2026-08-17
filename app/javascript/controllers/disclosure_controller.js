import { Controller } from "@hotwired/stimulus"

/*
 * A disclosure, replacing Bootstrap's data-bs-toggle="collapse".
 *
 * The trigger is a real <button> carrying aria-expanded and aria-controls, so the state is
 * announced. Bootstrap's collapse animates height in JS; this just toggles `hidden`, which
 * costs nothing and cannot leave a panel stuck mid-animation.
 *
 * With JS off, mark the panel as visible in the template: a disclosure that cannot be opened
 * must not be the only route to its content.
 */
export default class extends Controller {
  toggle(event) {
    const button = event.currentTarget
    const panel = document.getElementById(button.getAttribute("aria-controls"))
    if (!panel) return

    const isOpen = button.getAttribute("aria-expanded") === "true"
    button.setAttribute("aria-expanded", isOpen ? "false" : "true")
    panel.classList.toggle("hidden", isOpen)
    button.querySelector("[data-disclosure-chevron]")?.classList.toggle("rotate-180", !isOpen)
  }
}
