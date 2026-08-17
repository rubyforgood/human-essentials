import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["itemSubmitButton"]

  connect() {
    this.boundHandleSubmit = this.handleSubmit.bind(this)
    this.element.addEventListener("submit", this.boundHandleSubmit)
    
    // Disable Rails UJS for this form to prevent "Saving" state
    this.element.removeAttribute('data-remote')
    
    // Remove data-disable-with from all submit buttons
    const buttons = this.element.querySelectorAll('input[type="submit"], button[type="submit"]')
    buttons.forEach(button => {
      button.removeAttribute('data-disable-with')
    })
  }

  handleSubmit(event) {
    const submitter = event.submitter

    if (!this.itemSubmitButtonTargets.includes(submitter)) return

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
        const barcodeLine = entry.barcode ? `<div class="duplicate-barcode text-xs text-slate-500">Barcode: ${entry.barcode}</div>` : ''
        return `<div class="duplicate-entry text-sm text-slate-700">❐ ${item.name} : ${entry.quantity}${barcodeLine}</div>`
      }).join('')
      return `<div class="duplicate-container rounded-xl border border-slate-200 p-3">${rows}<div class="duplicate-merged mt-1 text-sm font-semibold text-slate-900">→ Merged Result: ${item.name} : ${total}</div></div>`
    }).join('')

// Native <dialog>: Bootstrap's modal JS and CSS are no longer loaded, so showModal()
// supplies the backdrop, focus trap and Escape key instead.
const modalHtml = `
  <dialog id="duplicateItemsModal"
          class="w-full max-w-lg rounded-2xl border border-slate-200 bg-white p-0 shadow-xl backdrop:bg-slate-900/40"
          aria-labelledby="duplicateItemsTitle">
    <div class="flex items-start justify-between gap-3 border-b border-slate-200 px-5 py-4">
      <h2 id="duplicateItemsTitle" class="text-base font-semibold text-slate-900">Multiple item entries detected</h2>
      <button type="button"
              class="rounded-lg p-1.5 text-slate-500 hover:bg-slate-100 hover:text-slate-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-600"
              aria-label="Close dialog"
              onclick="this.closest('dialog').close()">
        <i class="bi-x-lg text-sm" aria-hidden="true"></i>
      </button>
    </div>
    <div class="max-h-[60vh] overflow-y-auto px-5 py-4">
      <p class="text-sm font-semibold text-slate-900">The following items have multiple entries:</p>
      <div class="duplicate-items-list mt-3 space-y-3">${itemRows}</div>
    </div>
    <div class="border-t border-slate-200 px-5 py-3">
      <p class="duplicate-modal-text text-sm text-slate-600">
        Choose <strong>Merge items</strong> to combine quantities and continue, or <strong>Make changes</strong> to go back and edit.
      </p>
      <div class="duplicate-modal-buttons mt-3 flex flex-wrap justify-end gap-2">
        <button type="button" class="inline-flex items-center justify-center gap-1.5 rounded-lg border border-slate-300 bg-white px-3.5 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50" onclick="this.closest('dialog').close()">Make changes</button>
        <button type="button" class="inline-flex items-center justify-center gap-1.5 rounded-lg bg-brand-600 px-3.5 py-2 text-sm font-medium text-white hover:bg-brand-700" id="confirmMerge">Merge items</button>
      </div>
    </div>
  </dialog>
`

    document.getElementById('duplicateItemsModal')?.remove()
    document.body.insertAdjacentHTML('beforeend', modalHtml)
    
    document.getElementById('duplicateItemsModal').showModal()

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

    document.getElementById('duplicateItemsModal')?.close()

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
