import { Controller } from "@hotwired/stimulus"

/*
 * Reveals the panel that belongs to the checked radio and hides the others. A panel says which
 * answer it belongs to with `data-radio-reveal-value`; a radio with no panel hides them all.
 *
 * The server renders the initial state (design.md, "Render the state, do not correct it"), so
 * `connect()` only matters when the browser has restored a checked radio on Back -- and with
 * nothing checked it hides exactly what the server already hid, so it never un-draws anything.
 */
export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.toggle()
  }

  toggle() {
    const checked = this.element.querySelector("input[type=radio]:checked")
    this.panelTargets.forEach((panel) => {
      panel.classList.toggle("hidden", !checked || panel.dataset.radioRevealValue !== checked.value)
    })
  }
}
