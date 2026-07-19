import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="csv-download"
// Fetches a CSV file in the background and triggers a browser download.
//
// Usage:
//   <div data-controller="csv-download" data-csv-download-url-value="/some/path.csv"></div>
//
export default class extends Controller {
  static values = { url: String }

  connect() {
    fetch(this.urlValue, { headers: { "X-Requested-With": "XMLHttpRequest" } })
      .then(response => {
        if (!response.ok) return
        const filename = this._extractFilename(response.headers.get("Content-Disposition"))
        return response.blob().then(blob => ({ blob, filename }))
      })
      .then(({ blob, filename }) => {
        const objectUrl = URL.createObjectURL(blob)
        const anchor = document.createElement("a")
        anchor.href = objectUrl
        anchor.download = filename || "report.csv"
        anchor.click()
        URL.revokeObjectURL(objectUrl)
      })
  }

  _extractFilename(disposition) {
    if (!disposition) return null

    const utf8Match = disposition.match(/filename\*=UTF-8''([^;\n]+)/i)
    if (utf8Match) return decodeURIComponent(utf8Match[1])
    const plainMatch = disposition.match(/filename="?([^";\n]+)"?/i)
    return plainMatch ? plainMatch[1] : null
  }
}
