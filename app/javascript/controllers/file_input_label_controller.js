import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="file-input-label"
//
// Reproduces the native browser behavior of updating a file input label
// to show the selected file's name. This is necessary when using a custom
// file input, such as with Bootstrap, that does not update automatically.
//
// Key Features:
// 1. Handles initial display of a default label text (e.g., "Choose file..." or
//    the previously selected file name if present).
// 2. Updates the label dynamically when a new file is selected.
//
// How it works:
// - When a file is selected, the `fileSelected` method updates the text of the
//   label to reflect the name of the selected file.
// - On page load, the `connect` method ensures the label is initialized to the
//   correct state (default text or file name, if a file was previously selected).
//
// This controller is used in coordination with direct uploads in Active Storage.
// When a validation error occurs, previously selected files persist on the server
// (via direct upload), and the file name can be displayed to the user.
export default class extends Controller {
  static targets = ["input", "label"];
  static values = {
    defaultText: { type: String, default: 'Choose file...' }
  }

  connect() {
    this.updateLabel();
  }

  updateLabel() {
    const input = this.inputTarget;
    const label = this.labelTarget;

    // Check if the file input has a file selected
    if (input.files.length > 0) {
      label.textContent = input.files[0].name;
    } else {
      label.textContent = this.defaultTextValue;
    }
  }

  // Update the label when a file is selected
  fileSelected() {
    this.updateLabel();
  }
}
