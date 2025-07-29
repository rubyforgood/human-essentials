import { Controller } from "@hotwired/stimulus";

/**
 * Stimulus controller to enhance the file input UI for multiple files.
 *
 * This controller:
 * - Listens for file selection on an `<input type="file" multiple="multiple">`
 * - Displays selected file names in a custom list when multiple files are selected
 * - If provided a `filenames` array, displays those file names as if user had just selected them.
 *   This is useful for displaying previously selected files on page load with validation errors.
 *
 * Expected HTML structure should have a placeholder div for the selected file names:
 *
 * ```erb
 * <div data-controller="file-input">
 *   <input type="file" multiple data-file-input-target="input">
 *   <div data-file-input-target="list"></div>
 * </div>
 * ```
 */
export default class extends Controller {
  static targets = ["input", "list"];

  static values = {
    filenames: Array
  }

  connect() {
    this.inputTarget.addEventListener("change", () => this.updateFileList());

    if (this.hasFilenamesValue && this.filenamesValue.length > 0) {
      this.updateFileListFromValue();
    }
  }

  // Opens the hidden file input when "Choose Files" button is clicked
  triggerFileSelection() {
    this.inputTarget.click();
  }

  // native file input selection
  updateFileList() {
    const files = this.inputTarget.files;

    if (files.length === 0) {
      return;
    }

    this.renderFileList(Array.from(files).map(file => file.name));
  }

  updateFileListFromValue() {
    this.renderFileList(this.filenamesValue);
  }

  renderFileList(fileNames) {
    // Clear previous list
    this.listTarget.innerHTML = "";

    // Create subheader
    const header = document.createElement("p");
    header.textContent = "Selected files:";
    header.classList.add("font-weight-bold", "mb-1");

    // Create file list
    const ul = document.createElement("ul");
    ul.classList.add("list-unstyled", "mt-2");

    fileNames.forEach((name) => {
      const li = document.createElement("li");
      li.classList.add("p-1", "rounded", "mb-1");
      li.textContent = name;
      ul.appendChild(li);
    });

    // Append header and list to target container
    this.listTarget.appendChild(header);
    this.listTarget.appendChild(ul);
  }
}
