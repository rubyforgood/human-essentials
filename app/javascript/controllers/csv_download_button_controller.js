import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("click", this.handleClick.bind(this));
  }

  handleClick(event) {
    event.preventDefault();
    if (this.element.disabled) return;

    this.element.disabled = true;
    this.originalButtonText = this.element.textContent;
    this.element.textContent = "Please wait...";

    let filename = "export";

    const url = this.element.href
    fetch(url, { headers: { Accept: "text/csv" } })
    .then(response => {
      const contentType = response.headers.get("content-type");
      if (!response.ok) {
        throw new Error(`HTTP error. Status: ${response.status}`);
      }
      if (!contentType.includes("text/csv")) {
        throw new Error(`Unexpected content type: ${contentType}`);
      }

      if(this.extractFilename(response)) {
        filename = this.extractFilename(response);
      }

      return response.blob();
    })
    .then(blob => {
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = filename;
      a.click();
      URL.revokeObjectURL(a.href);
    })
    .catch((error) => console.log(`CSV Download failed: ${error}`)
    )
    .finally(() => {
      this.element.textContent = this.originalButtonText;
      this.element.disabled = false;
    })
  }

  extractFilename(response) {
    const contentDisposition = response.headers.get("content-disposition");
    const match = contentDisposition.match(/filename="([^"]*)"/);
    return match ? match[1] : null;
  }
}
