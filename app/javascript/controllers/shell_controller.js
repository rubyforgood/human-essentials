import { Controller } from "@hotwired/stimulus"

/*
 * App shell chrome for the Ruby for Good design system layout (layouts/essentials_app).
 *
 * Owns two independent bits of state so they cannot fight each other:
 *   - the off-canvas sidebar drawer below the `lg` breakpoint
 *   - each collapsible sidebar nav group
 *
 * The account menu used to live here too. It is an anchored floating panel like any other, so it
 * belongs to `popover`, which already has the outside-click, Escape and focus-return behaviour
 * that this controller was duplicating for it alone.
 *
 * Everything here is progressive enhancement. With JS off the drawer is irrelevant (the sidebar
 * is statically visible at `lg`) and every nav group renders open.
 */
export default class extends Controller {
  static targets = ["drawer", "scrim", "drawerToggle"]

  connect() {
    this.closeOnEscape = this.closeOnEscape.bind(this)
    document.addEventListener("keydown", this.closeOnEscape)
  }

  disconnect() {
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  // --- Sidebar drawer (mobile) ---------------------------------------------

  openDrawer() {
    this.drawerTarget.classList.remove("-translate-x-full")
    this.scrimTarget.classList.remove("hidden")
    this.drawerToggleTarget.setAttribute("aria-expanded", "true")
    // Focus the drawer so the next Tab lands inside it rather than back in the page.
    this.drawerTarget.focus()
  }

  closeDrawer() {
    this.drawerTarget.classList.add("-translate-x-full")
    this.scrimTarget.classList.add("hidden")
    this.drawerToggleTarget.setAttribute("aria-expanded", "false")
    this.drawerToggleTarget.focus()
  }

  toggleDrawer() {
    const isOpen = this.drawerToggleTarget.getAttribute("aria-expanded") === "true"
    isOpen ? this.closeDrawer() : this.openDrawer()
  }

  // --- Collapsible nav groups ----------------------------------------------

  toggleGroup(event) {
    const button = event.currentTarget
    const panel = document.getElementById(button.getAttribute("aria-controls"))
    if (!panel) return

    const isOpen = button.getAttribute("aria-expanded") === "true"
    button.setAttribute("aria-expanded", isOpen ? "false" : "true")
    panel.classList.toggle("hidden", isOpen)
    button.querySelector("[data-shell-chevron]")?.classList.toggle("rotate-180", !isOpen)
  }

  // --- Shared ---------------------------------------------------------------

  closeOnEscape(event) {
    if (event.key !== "Escape") return
    if (this.hasDrawerToggleTarget && this.drawerToggleTarget.getAttribute("aria-expanded") === "true") {
      this.closeDrawer()
    }
  }
}
