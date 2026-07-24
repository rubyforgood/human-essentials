import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "name", "message"]
  static values = { lookupUrl: String }

  async lookup() {
    const email = this.emailTarget.value.trim()

    if (email === "") {
      this.resetNameField()
      return
    }

    try {
      const response = await fetch(`${this.lookupUrlValue}?email=${encodeURIComponent(email)}`, {
        headers: { "Accept": "application/json" }
      })
      if (!response.ok || this.emailTarget.value.trim() !== email) return

      const user = await response.json()
      if (!user.exists) {
        this.resetNameField()
      } else {
        this.nameTarget.disabled = false
        this.messageTarget.textContent = "This user already exists. The submitted name will only be used if their profile has no name yet."
      }
    } catch (_error) {
      this.resetNameField()
    }
  }

  resetNameField() {
    this.nameTarget.disabled = false
    this.messageTarget.textContent = ""
  }
}
