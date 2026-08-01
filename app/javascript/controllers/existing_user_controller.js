import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "name", "message"]
  static values = { lookupUrl: String }

  disconnect() {
    this.abortController?.abort()
  }

  async lookup() {
    this.abortController?.abort()
    this.abortController = new AbortController()

    const email = this.emailTarget.value.trim()

    if (email === "") {
      this.resetNameField()
      return
    }

    try {
      const response = await fetch(`${this.lookupUrlValue}?email=${encodeURIComponent(email)}`, {
        headers: { "Accept": "application/json" },
        signal: this.abortController.signal
      })
      if (!response.ok || this.emailTarget.value.trim() !== email) return

      const user = await response.json()
      if (!user.exists) {
        this.resetNameField()
      } else {
        this.nameTarget.disabled = false
        this.messageTarget.textContent = "This user already exists. Their current profile name will be kept; the submitted name is used only if their profile has no name yet."
      }
    } catch (error) {
      if (error.name !== "AbortError") this.messageTarget.textContent = ""
    }
  }

  resetNameField() {
    this.nameTarget.disabled = false
    this.messageTarget.textContent = ""
  }
}
