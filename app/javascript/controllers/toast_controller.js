import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toast"
// Shows a toastr notification when the element is rendered.
//
// Usage:
//   <div data-controller="toast" data-toast-message-value="Hello!" data-toast-type-value="info"></div>
//
export default class extends Controller {
  static values = {
    message: String,
    type: { type: String, default: "info" },
    timeout: { type: Number, default: 5000 },
    position: { type: String, default: "toast-top-center" }
  }

  connect() {
    const previousTimeout = toastr.options.timeOut;
    const previousPosition = toastr.options.positionClass;
    toastr.options.timeOut = this.timeoutValue;
    toastr.options.positionClass = this.positionValue;
    toastr[this.typeValue](this.messageValue);
    toastr.options.timeOut = previousTimeout;
    toastr.options.positionClass = previousPosition;
  }
}
