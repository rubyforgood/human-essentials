import { Controller } from "@hotwired/stimulus"

/*
 * App shell chrome for the Ruby for Good design system layout (layouts/essentials_app).
 *
 * Owns three independent bits of state so they cannot fight each other:
 *   - the off-canvas sidebar drawer below the `lg` breakpoint
 *   - the top-bar account menu
 *   - each collapsible sidebar nav group
 *
 * Everything here is progressive enhancement. With JS off the drawer is irrelevant
 * (the sidebar is statically visible at `lg`), the account menu's links are still
 * reachable, and every nav group renders open.
 */
export default class extends Controller {
  static targets = ["drawer", "scrim", "drawerToggle", "accountMenu", "accountToggle"]

  connect() {
    this.closeOnEscape = this.closeOnEscape.bind(this)
    this.closeAccountOnOutsideClick = this.closeAccountOnOutsideClick.bind(this)
    document.addEventListener("keydown", this.closeOnEscape)
    document.addEventListener("click", this.closeAccountOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener("keydown", this.closeOnEscape)
    document.removeEventListener("click", this.closeAccountOnOutsideClick)
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

  // --- Account menu ---------------------------------------------------------

  toggleAccount(event) {
    event.stopPropagation()
    const isOpen = this.accountToggleTarget.getAttribute("aria-expanded") === "true"
    this.accountToggleTarget.setAttribute("aria-expanded", isOpen ? "false" : "true")
    this.accountMenuTarget.classList.toggle("hidden", isOpen)
  }

  closeAccount() {
    if (!this.hasAccountMenuTarget) return
    this.accountToggleTarget.setAttribute("aria-expanded", "false")
    this.accountMenuTarget.classList.add("hidden")
  }

  closeAccountOnOutsideClick(event) {
    if (!this.hasAccountMenuTarget) return
    if (this.accountMenuTarget.classList.contains("hidden")) return
    if (this.element.querySelector("[data-shell-target='accountMenu']")?.contains(event.target)) return
    if (this.accountToggleTarget.contains(event.target)) return
    this.closeAccount()
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
    this.closeAccount()
    if (this.hasDrawerToggleTarget && this.drawerToggleTarget.getAttribute("aria-expanded") === "true") {
      this.closeDrawer()
    }
  }
}
