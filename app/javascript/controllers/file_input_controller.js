import { Controller } from "@hotwired/stimulus";

/**
 * Stimulus controller to enhance the file input UI for multiple files.
 *
 * This controller:
 * - Listens for file selection on an `<input type="file" multiple="multiple">`
 * - Displays selected file names in a custom list **when multiple files are selected
 * - Defaults to the browser’s built-in display for a single file selection
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

  connect() {
    this.inputTarget.addEventListener("change", () => this.updateFileList());
  }

  updateFileList() {
    const files = this.inputTarget.files;
    this.listTarget.innerHTML = ""; // Clear previous list

    // If no files or only one file is selected, let the native UI handle it
    if (files.length <= 1) {
      return;
    }

    const ul = document.createElement("ul");
    ul.classList.add("list-unstyled", "mt-2");

    Array.from(files).forEach((file) => {
      const li = document.createElement("li");
      li.classList.add("p-1", "rounded", "mb-1");
      li.textContent = file.name;
      ul.appendChild(li);
    });

    this.listTarget.appendChild(ul);
  }
}
