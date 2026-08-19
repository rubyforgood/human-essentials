import { Controller } from "@hotwired/stimulus"

// Makes the Trix toolbar keyboard-operable.
//
// Trix renders its toolbar as 14 buttons, every one of them tabindex="-1", with no role and no
// arrow-key handling. So bold, italic and link are reachable by their shortcuts and the rest --
// headings, quotes, code, both list types, indent, outdent, attach -- are reachable by nothing.
// That is WCAG 2.1.1: the functionality exists and the keyboard cannot get to it.
//
// The fix is the standard ARIA toolbar pattern rather than making all 14 tab stops, which would
// put a dozen presses between a rich text field and the next control. One button is in the tab
// order; arrow keys move within the group.
//
// Attached to the app shell rather than to each field, and driven by trix-initialize, so it
// covers every rich text area including ones rendered later.
export default class extends Controller {
  connect() {
    this.onInitialize = this.enhanceFrom.bind(this);
    document.addEventListener("trix-initialize", this.onInitialize);
    // Anything already on the page when this connects.
    document.querySelectorAll("trix-toolbar").forEach((toolbar) => this.enhance(toolbar));
  }

  disconnect() {
    document.removeEventListener("trix-initialize", this.onInitialize);
  }

  enhanceFrom(event) {
    const editor = event.target;
    const toolbar = editor.toolbarElement ||
      (editor.getAttribute("toolbar") && document.getElementById(editor.getAttribute("toolbar")));
    if (toolbar) this.enhance(toolbar);
  }

  enhance(toolbar) {
    if (toolbar.dataset.toolbarEnhanced) return;
    toolbar.dataset.toolbarEnhanced = "true";

    toolbar.setAttribute("role", "toolbar");
    if (!toolbar.getAttribute("aria-label")) toolbar.setAttribute("aria-label", "Text formatting");

    // Trix names its buttons with `title`. That is an accessible name, but a weak one, so it is
    // copied to aria-label where there is nothing better.
    this.buttons(toolbar).forEach((button) => {
      const title = button.getAttribute("title");
      if (title && !button.getAttribute("aria-label")) button.setAttribute("aria-label", title);
    });

    this.setTabStop(toolbar, 0);
    toolbar.addEventListener("keydown", (event) => this.navigate(event, toolbar));
    // Trix swaps the button set when a dialog opens, so the tab stop is re-established on focus.
    toolbar.addEventListener("focusin", (event) => {
      const buttons = this.buttons(toolbar);
      const index = buttons.indexOf(event.target);
      if (index >= 0) this.setTabStop(toolbar, index);
    });
  }

  buttons(toolbar) {
    return [...toolbar.querySelectorAll("button")].filter((b) => b.offsetParent !== null && !b.disabled);
  }

  setTabStop(toolbar, index) {
    const buttons = this.buttons(toolbar);
    buttons.forEach((button, i) => button.setAttribute("tabindex", i === index ? "0" : "-1"));
  }

  navigate(event, toolbar) {
    const buttons = this.buttons(toolbar);
    const current = buttons.indexOf(document.activeElement);
    if (current < 0) return;

    let next = null;
    switch (event.key) {
      case "ArrowRight": next = (current + 1) % buttons.length; break;
      case "ArrowLeft": next = (current - 1 + buttons.length) % buttons.length; break;
      case "Home": next = 0; break;
      case "End": next = buttons.length - 1; break;
      default: return;
    }
    event.preventDefault();
    this.setTabStop(toolbar, next);
    buttons[next].focus();
  }
}
