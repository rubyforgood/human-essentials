import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["password", "icon"];

  toggle() {
    const isPasswordVisible = this.passwordTarget.type === "text";

    this.passwordTarget.type = isPasswordVisible ? "password" : "text";
    this.iconTarget.classList.toggle("fa-eye", !isPasswordVisible);
    this.iconTarget.classList.toggle("fa-eye-slash", isPasswordVisible);
  }
}
