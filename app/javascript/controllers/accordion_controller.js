import { Controller } from "@hotwired/stimulus";

// TODO: 4504 - probably many edge cases including:
// 1. User closes the current section
// 2. User opens a new section while everything is closed
// 3. Is 300 ms the right delay value for coordinating open/close events?

// Connects to data-controller="accordion"
// Capture the form in the closed section and wait to submit it when the new section is opened, detect explicit close or open without hide.
export default class extends Controller {
  connect() {
    this.formToSubmit = null; // Keep track of the form to submit when a new section opens
    this.isNewSectionOpening = false; // Flag to determine if a new section is being opened
    this.previousEventWasHide = false; // Track if the previous event was a 'hidden' event

    // Handle collapse (hidden) event
    this.element.addEventListener(
      "hidden.bs.collapse",
      this.onSectionHidden.bind(this)
    );

    // Handle expand (shown) event
    this.element.addEventListener(
      "shown.bs.collapse",
      this.onSectionShown.bind(this)
    );
  }

  disconnect() {
    this.element.removeEventListener( "hidden.bs.collapse" );
    this.element.removeEventListener( "shown.bs.collapse" );
  }

  // Called when an accordion section is collapsed
  onSectionHidden(event) {
    console.log("=== SECTION HIDDEN", event);
    const form = event.target.querySelector("form");

    // Save the form to submit later when the new section opens
    if (form) {
      this.formToSubmit = form;
    }

    // Set the flag to indicate the previous event was a hide event
    this.previousEventWasHide = true;

    // Check if the user explicitly closed the section by waiting for the shown event
    setTimeout(() => {
      if (!this.isNewSectionOpening) {
        // This means the user explicitly closed the section
        console.log("=== SECTION EXPLICITLY CLOSED BY THE USER");
        // TODO: 4504 - should we submit the form that just got closed now?
      }
    }, 300);
  }

  // Called when an accordion section is expanded
  onSectionShown(event) {
    console.log("=== SECTION SHOWN", event);
    // Check if this is a show event without a preceding hide event
    if (!this.previousEventWasHide) {
      console.log("=== SHOW EVENT WITHOUT PRECEDING HIDE EVENT");
      // TODO: 4504 - anything special to do here?
    }

    // Flag that a new section is opening
    this.isNewSectionOpening = true;

    // Submit the form from the previously closed section (if any)
    if (this.formToSubmit) {
      const hiddenInput = document.createElement("input");
      hiddenInput.type = "hidden";
      hiddenInput.name = "open_section_override"; // Rails naming convention?
      hiddenInput.value = event.target.id;

      this.formToSubmit.appendChild(hiddenInput);
      this.formToSubmit.requestSubmit();
      this.formToSubmit = null; // Clear the form reference after submission
    }

    // Reset the flag after a small delay to account for user interactions
    setTimeout(() => {
      this.isNewSectionOpening = false;
      this.previousEventWasHide = false; // Reset the flag after the shown event
    }, 300);
  }
}
