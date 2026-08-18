import { Controller } from "@hotwired/stimulus"

/*
 * Tabs, following the WAI-ARIA tabs pattern.
 *
 * Progressive enhancement: with JS off every panel is visible and the tab list reads as a
 * set of in-page links, so no content is unreachable. On connect the panels collapse to one.
 *
 * Keyboard support is the part hand-rolled tab strips usually miss: Left/Right move between
 * tabs, Home/End jump to the ends, and only the active tab is in the tab order (roving
 * tabindex), so Tab moves out of the strip rather than through every tab in it.
 */
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.select(this.tabFromHash() ?? this.tabTargets.findIndex((t) => t.getAttribute("aria-selected") === "true"))
  }

  // Links elsewhere in the app point at a specific tab by fragment -- the partner approval
  // queue links to #partner-information, for one. Bootstrap's tab plugin used to do this from
  // a jQuery block in application.js; it belongs with the tabs.
  tabFromHash() {
    const hash = window.location.hash
    if (!hash) return null

    const index = this.tabTargets.findIndex(
      (tab) => tab.getAttribute("href") === hash || `#${tab.getAttribute("aria-controls")}` === hash
    )
    return index === -1 ? null : index
  }

  activate(event) {
    event.preventDefault()
    this.select(this.tabTargets.indexOf(event.currentTarget))
  }

  navigate(event) {
    const keys = { ArrowRight: 1, ArrowLeft: -1 }
    const current = this.tabTargets.indexOf(event.currentTarget)

    let next
    if (keys[event.key] !== undefined) {
      next = (current + keys[event.key] + this.tabTargets.length) % this.tabTargets.length
    } else if (event.key === "Home") {
      next = 0
    } else if (event.key === "End") {
      next = this.tabTargets.length - 1
    } else {
      return
    }

    event.preventDefault()
    this.select(next)
    this.tabTargets[next].focus()
  }

  select(index) {
    const active = index < 0 ? 0 : index

    this.tabTargets.forEach((tab, i) => {
      const on = i === active
      tab.setAttribute("aria-selected", on ? "true" : "false")
      tab.setAttribute("tabindex", on ? "0" : "-1")
      tab.classList.toggle("border-brand-600", on)
      tab.classList.toggle("text-brand-700", on)
      tab.classList.toggle("border-transparent", !on)
      tab.classList.toggle("text-slate-600", !on)
    })

    this.panelTargets.forEach((panel, i) => panel.classList.toggle("hidden", i !== active))
  }
}
