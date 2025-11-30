import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    document.addEventListener("turbo:frame-render", this.openModalHandler)
    document.addEventListener("turbo:submit-end", this.closeModalHandler)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-render", this.openModalHandler)
    document.removeEventListener("turbo:submit-end", this.closeModalHandler)
  }

  handleNewSelect(event) {
    const value = event.target.value
    if (value === "new") {
      const url = event.target.dataset.url
      Turbo.visit(url, { frame: 'modal-new' })
    }
  }

  openModalHandler = () => {
    const modal = document.getElementById("modal-new")
    const instance = bootstrap.Modal.getOrCreateInstance(modal)
    instance.show()
  }

  closeModalHandler = (event) => {
    if (event.detail.success) {
      const modal = document.getElementById("modal-new")
      const instance = bootstrap.Modal.getOrCreateInstance(modal)
      instance.hide()
    }
  }
}
