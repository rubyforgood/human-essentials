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
    this.syncInert = this.syncInert.bind(this)
    document.addEventListener("keydown", this.closeOnEscape)
    window.addEventListener("resize", this.syncInert)
    this.syncInert()
  }

  disconnect() {
    document.removeEventListener("keydown", this.closeOnEscape)
    window.removeEventListener("resize", this.syncInert)
  }

  // The drawer is moved off screen with a transform, which hides it from the eye and from nobody
  // else: closed, its 27 links stayed in the tab order, so a keyboard user tabbed from "Skip to
  // main content" through the entire navigation -- invisible -- before reaching the page.
  // `inert` is what actually removes a subtree: out of the tab order and out of the
  // accessibility tree, without the display: none that would break the slide.
  //
  // Recomputed on resize as well, because at `lg` the sidebar is a visible column and must not
  // be inert no matter what the drawer's last state was.
  syncInert() {
    if (!this.hasDrawerTarget) return

    const atDesktop = window.matchMedia("(min-width: 1024px)").matches
    const open = this.hasDrawerToggleTarget &&
                 this.drawerToggleTarget.getAttribute("aria-expanded") === "true"

    this.drawerTarget.inert = !atDesktop && !open
  }

  // --- Sidebar drawer (mobile) ---------------------------------------------

  openDrawer() {
    this.drawerTarget.inert = false
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
    // After the focus move, or the browser is asked to blur an element it is about to make inert.
    this.syncInert()
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
