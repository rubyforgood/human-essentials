import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundHandleSubmit = this.handleSubmit.bind(this)
    this.element.addEventListener("submit", this.boundHandleSubmit)
  }

  handleSubmit(event) {
    const submitter = event.submitter

    if (!submitter?.name) return
    if (!submitter.name.includes('save_progress') && 
        !submitter.name.includes('confirm_audit')) {
      return
    }

    event.preventDefault()
    
    const duplicates = this.findDuplicates()
    
    if (duplicates.length > 0) {
      this.showModal(duplicates, submitter.name)
    } else {
      this.submitForm(submitter.name)
    }
  }

  findDuplicates() {
    const itemCounts = {}
    const itemData = {}

    this.element.querySelectorAll('select[name*="[item_id]"]').forEach(select => {
      const itemId = select.value
      const itemText = select.options[select.selectedIndex]?.text
      const section = select.closest('.line_item_section')
      const quantityInput = section?.querySelector('input[name*="[quantity]"]')
      const quantity = parseInt(quantityInput?.value) || 0
      const barcodeValue = section?.querySelector('.__barcode_item_lookup')?.value || ''

      if (!itemId || itemText === "Choose an item" || quantity === 0) return

      itemCounts[itemId] = (itemCounts[itemId] || 0) + 1
      if (!itemData[itemId]) {
        itemData[itemId] = { name: itemText, entries: [] }
      }
      itemData[itemId].entries.push({ quantity, section, barcode: barcodeValue })
    })

    return Object.keys(itemCounts)
      .filter(id => itemCounts[id] > 1)
      .map(id => itemData[id])
  }

  showModal(duplicates, buttonName) {
    const itemRows = duplicates.map(item => {
      const entries = item.entries
      const total = entries.reduce((sum, entry) => sum + entry.quantity, 0)
      const rows = entries.map(entry => {
        const barcodeLine = entry.barcode ? `<div class="duplicate-barcode">Barcode: ${entry.barcode}</div>` : ''
        return `<div class="duplicate-entry">❐ ${item.name} : ${entry.quantity}${barcodeLine}</div>`
      }).join('')
      return `<div class="duplicate-container">${rows}<div class="duplicate-merged">→ Merged Result: ${item.name} : ${total}</div></div>`
    }).join('')

    const modalHtml = `
      <div class="modal fade" id="duplicateItemsModal" tabindex="-1">
        <div class="modal-dialog modal-dialog-scrollable">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">Multiple Item Entries Detected</h5>
              <button type="button" class="close" data-bs-dismiss="modal">
                <span>&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <p><strong>The following items have multiple entries:</strong></p>
              <div class="duplicate-items-list">${itemRows}</div>
            </div>
            <div class="modal-footer duplicate-modal-footer">
              <p class="duplicate-modal-text">
                Choose <strong>Merge Items</strong> to combine quantities and continue, or <strong>Make Changes</strong> to go back and edit.
              </p>
              <div class="duplicate-modal-buttons">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Make Changes</button>
                <button type="button" class="btn btn-success" id="confirmMerge">Merge Items</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    `

    document.getElementById('duplicateItemsModal')?.remove()
    document.body.insertAdjacentHTML('beforeend', modalHtml)
    
    const modal = new bootstrap.Modal(document.getElementById('duplicateItemsModal'))
    modal.show()
    
    document.getElementById('confirmMerge').addEventListener('click', () => {
      this.mergeAndSubmit(duplicates, buttonName)
    })
  }

  mergeAndSubmit(duplicates, buttonName) {
    duplicates.forEach(item => {
      const total = item.entries.reduce((sum, entry) => sum + entry.quantity, 0)

      // Separate the first entry from remaining entries
      const [firstEntry, ...remainingEntries] = item.entries
      
      // Update the first entry with the merged total
      firstEntry.section.querySelector('input[name*="[quantity]"]').value = total
      
      // Remove all duplicate entries from the form submission
      remainingEntries.forEach(entry => entry.section.remove())
    })

    const modal = new bootstrap.Modal(document.getElementById('duplicateItemsModal'))
    modal.hide()
    
    this.submitForm(buttonName)
  }

  submitForm(buttonName) {
    this.element.removeEventListener('submit', this.boundHandleSubmit)
    
    const input = document.createElement('input')
    input.type = 'hidden'
    input.name = buttonName
    input.value = '1'
    this.element.appendChild(input)
    
    this.element.submit()
  }
}
