import { Controller } from "@hotwired/stimulus"
import Rails from "@rails/ujs"

// Connects to data-controller="download"
// Fetches a file in the background and hands it to the browser as a download, so a download
// button can stay disabled until the file actually arrives (#5691). rails-ujs only re-enables
// a disabled link on the next page load, and a file download never triggers one.
//
// Usage:
//   <a href="/donations.csv" data-controller="download" data-action="download#download">
//   <div data-controller="download" data-download-url-value="/some/path.csv"></div>  (downloads on connect)
//
export default class extends Controller {
  static values = { url: String }

  connect() {
    if (this.hasUrlValue) this.fetchFile(this.urlValue)
  }

  async download(event) {
    // Let new-tab clicks through to the browser. These are the same ones rails-ujs skips, so the
    // link is never left disabled.
    if (event.metaKey || event.ctrlKey || event.button !== 0) return
    event.preventDefault()
    if (this.busy) return

    this.busy = true
    Rails.disableElement(this.element)
    try {
      await this.fetchFile(this.element.href)
    } finally {
      Rails.enableElement(this.element)
      this.busy = false
    }
  }

  async fetchFile(url) {
    try {
      // fetch never exposes a 3xx to JS: it either follows it or, in manual mode, returns an
      // opaque response with no Location. Following it here would also use up the flash that
      // export redirects (handle_csv_export) rely on, so let the browser make the request instead.
      // That means a redirecting endpoint is requested twice, so it must not do work before redirecting.
      const response = await fetch(url, { redirect: "manual", headers: { "X-Requested-With": "XMLHttpRequest" } })
      if (response.type === "opaqueredirect") {
        window.location.href = url
        return
      }
      // Signed out: reloading the page sends the user to the login screen.
      if (response.status === 401) {
        window.location.reload()
        return
      }
      if (!response.ok) throw new Error(`Download failed with status ${response.status}`)

      const filename = this._extractFilename(response.headers.get("Content-Disposition"))
      const objectUrl = URL.createObjectURL(await response.blob())
      const anchor = document.createElement("a")
      anchor.href = objectUrl
      anchor.download = filename || new URL(url, window.location.href).pathname.split("/").pop()
      anchor.click()
      // Revoking in the same tick can cancel the download in Safari.
      setTimeout(() => URL.revokeObjectURL(objectUrl), 1000)
    } catch (error) {
      console.error(error)
      window.toastr.error("Sorry, the download failed. Please try again.", "", { timeOut: 5000 })
    }
  }

  _extractFilename(disposition) {
    if (!disposition) return null

    const utf8Match = disposition.match(/filename\*=UTF-8''([^;\n]+)/i)
    if (utf8Match) return decodeURIComponent(utf8Match[1])
    const plainMatch = disposition.match(/filename="?([^";\n]+)"?/i)
    return plainMatch ? plainMatch[1] : null
  }
}
