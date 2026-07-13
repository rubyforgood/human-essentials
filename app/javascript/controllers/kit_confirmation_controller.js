import { Controller } from "@hotwired/stimulus"

/**
 * Connects to data-controller="kit-confirmation" on the new/edit Kit form.
 * Shows a preview of the kit's name, value, and item composition when the
 * user clicks Save, before the form is actually submitted. Composed with
 * the (shared, kit-agnostic) duplicate-items controller: confirming here
 * re-submits the form so duplicate-items can run its own check afterward.
 */
export default class extends Controller {
  static targets = ["submitButton"]

  openModal(event) {
    const submitter = event.currentTarget

    if (!this.submitButtonTargets.includes(submitter)) return

    event.preventDefault()

    this.showConfirmationModal(submitter)
  }

  collectLineItems() {
    const items = []

    this.element.querySelectorAll('select[name*="[item_id]"]').forEach(select => {
      const itemId = select.value
      const itemText = select.options[select.selectedIndex]?.text
      const section = select.closest('.line_item_section')
      const quantityInput = section?.querySelector('input[name*="[quantity]"]')
      const quantity = parseInt(quantityInput?.value) || 0

      if (!itemId || itemText === "Choose an item" || quantity === 0) return

      items.push({ name: itemText, quantity })
    })

    return items
  }

  showConfirmationModal(submitter) {
    const name = this.element.querySelector('#kit_name')?.value || ''
    const value = parseFloat(this.element.querySelector('#kit_value_in_dollars')?.value || 0).toFixed(2)
    const items = this.collectLineItems()

    const itemRows = items.map(item =>
      `<tr><td>${item.name}</td><td>${item.quantity}</td></tr>`
    ).join('')

    const modalHtml = `
      <div class="modal fade" id="kitConfirmationModal" tabindex="-1">
        <div class="modal-dialog modal-lg">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">Kit Creation Confirmation</h5>
              <button type="button" class="close" data-bs-dismiss="modal">
                <span>&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <p class="lead">You are about to create a kit named
                <span class="fw-bolder fst-italic" data-testid="kit-confirmation-name">${name}</span>
                with value
                <span class="fw-bolder fst-italic" data-testid="kit-confirmation-value">$${value}</span>
              </p>
              <table class="table">
                <thead>
                  <tr>
                    <th>Item Name</th>
                    <th>Quantity</th>
                  </tr>
                </thead>
                <tbody>${itemRows}</tbody>
              </table>
              <p>Please confirm that this is the correct composition of the kit. Note: You will
                <span class="text-danger fw-bold">not</span> be able to edit the items contained in the kit.</p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">No, I need to make changes</button>
              <button type="button" class="btn btn-success" id="kitConfirmationYes">Yes, it's correct</button>
            </div>
          </div>
        </div>
      </div>
    `

    document.getElementById('kitConfirmationModal')?.remove()
    document.body.insertAdjacentHTML('beforeend', modalHtml)

    const modal = new bootstrap.Modal(document.getElementById('kitConfirmationModal'))
    modal.show()

    document.getElementById('kitConfirmationYes').addEventListener('click', () => {
      modal.hide()
      this.element.requestSubmit(submitter)
    })
  }
}
