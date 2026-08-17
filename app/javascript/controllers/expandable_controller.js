import { Controller } from "@hotwired/stimulus"

/*
 * Expandable table rows, replacing AdminLTE's data-widget="expandable-table" jQuery plugin
 * (whose CSS and JS are both absent on design system pages).
 *
 * Each summary row holds a real <button> that toggles the detail row beneath it. The button
 * carries aria-expanded and aria-controls, so the state is announced -- the AdminLTE widget
 * put aria-expanded on the <tr> and left the affordance as a CSS ::before glyph on a cell,
 * which is not focusable and not operable by keyboard at all.
 */
export default class extends Controller {
  toggle(event) {
    const button = event.currentTarget
    const detail = document.getElementById(button.getAttribute("aria-controls"))
    if (!detail) return

    const isOpen = button.getAttribute("aria-expanded") === "true"
    button.setAttribute("aria-expanded", isOpen ? "false" : "true")
    detail.classList.toggle("hidden", isOpen)
    button.querySelector("[data-expandable-chevron]")?.classList.toggle("rotate-90", !isOpen)
  }
}
