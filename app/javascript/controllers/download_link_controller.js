import { Controller } from "@hotwired/stimulus"
import Rails from "@rails/ujs"

// Connects to data-controller="download-link"
// A download link serves a file instead of a new page, so rails-ujs never re-enables it after
// `data-disable-with` kicks in (#5691). Re-enable it after a delay instead: long enough to stop
// double-clicks from starting a second copy of a slow report, short enough not to stay stuck.
const REENABLE_DELAY_MS = 5000

export default class extends Controller {
  connect() {
    this.reenable = () => {
      clearTimeout(this.timeout)
      this.timeout = setTimeout(() => Rails.enableElement(this.element), REENABLE_DELAY_MS)
    }
    this.element.addEventListener("click", this.reenable)
  }

  disconnect() {
    this.element.removeEventListener("click", this.reenable)
    clearTimeout(this.timeout)
  }
}
