import $ from 'jquery';

$(() => {
  function checkForDuplicates(e, buttonName) {
    const form = $(this).closest('form');
    const itemCounts = {}; // Will look like: { "2": 3, "5": 1, "12": 2 }
    const itemNames = {}; // Will look like: { "2": "Item A", "5": "Item B", "12": "Item C" }
    const itemQuantities = {}; // Will look like: { "2": [{qty: 15, barcode: "123"}, {qty: 10, barcode: "456"}] }

    form.find('select[name$="[item_id]"]').each(function() {
      const itemId = $(this).val();
      const itemText = $(this).find('option:selected').text();
      const section = $(this).closest('.line_item_section');
      const quantityInput = section.find('input[name*="[quantity]"]');
      const itemQuantity = parseInt(quantityInput.val()) || 0;
      const barcodeValue = section.find('.__barcode_item_lookup').val() || '';
      
      if (!itemId || itemText === "Choose an item" || itemQuantity === 0) {
        section.remove();
        return;
      }
      
      itemCounts[itemId] = (itemCounts[itemId] || 0) + 1;
      itemNames[itemId] = itemText;
      if (!itemQuantities[itemId]) itemQuantities[itemId] = [];
      itemQuantities[itemId].push({ qty: itemQuantity, barcode: barcodeValue });
    });
    
    // Check for duplicates
    const duplicates = Object.keys(itemCounts)
      .filter(itemId => itemCounts[itemId] > 1)
      .map(itemId => ({ name: itemNames[itemId], id: itemId }));

    if (duplicates.length > 0) {
      // Show modal with duplicate items
      showDuplicateModal(duplicates, itemQuantities, form, buttonName);
      e.preventDefault();
    } 
    // else, allow form submission to proceed
  }

  $("button[name='save_progress']").on('click', function (e) {
    checkForDuplicates.call(this, e, 'save_progress');
  });

  $("button[name='confirm_audit']").on('click', function (e) {
    checkForDuplicates.call(this, e, 'confirm_audit');
  });

  function showDuplicateModal(duplicateItems, duplicateQuantities, form, buttonName) {
    const itemRows = duplicateItems.map(item => {
      const entries = duplicateQuantities[item.id] || [];
      const total = entries.reduce((sum, entry) => sum + entry.qty, 0);
      const rows = entries.map((entry, i) => {
        const barcodeLine = entry.barcode ? `<div class="duplicate-barcode">Barcode: ${entry.barcode}</div>` : '';
        return `<div class="duplicate-entry">❐ ${item.name} : ${entry.qty}${barcodeLine}</div>`;
      }).join('');
      return `<div class="duplicate-container">${rows}<div class="duplicate-merged">→ Merged Result: ${item.name} : ${total}</div></div>`;
    }).join('');
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
    `;
    
    // Remove existing modal
    $('#duplicateItemsModal').remove();
    
    // Add and show modal
    $('body').append(modalHtml);
    $('#duplicateItemsModal').modal('show');
    
    // Handle close button
    $('#duplicateItemsModal .close').on('click', function() {
      $('#duplicateItemsModal').modal('hide');
    });
    
    // Handle Merge Items button
    $('#confirmMerge').on('click', function() {
      $('#duplicateItemsModal').modal('hide');
      
      // Merge duplicate items before submitting
      mergeDuplicateItems(form);
      
      // Create a hidden button with the appropriate name to ensure proper parameter submission
      const hiddenBtn = $(`<button type="submit" name="${buttonName}" style="display:none;"></button>`);
      form.append(hiddenBtn);
      
      // Click the hidden button to submit with the correct parameter
      hiddenBtn.trigger('click');
    });
  }
  
  function mergeDuplicateItems(form) {
    const itemQuantities = {};
    const itemSections = [];
    
    // Collect all line items and their quantities
    form.find('select[name$="[item_id]"]').each(function() {
      const itemId = $(this).val();
      const section = $(this).closest('.line_item_section');
      const quantityInput = section.find('input[name*="[quantity]"]');
      const quantity = parseInt(quantityInput.val()) || 0;
      
      if (itemId && itemId !== '') {
        itemSections.push({ itemId, section, quantity });
        itemQuantities[itemId] = (itemQuantities[itemId] || 0) + quantity;
      }
    });
    
    // Find duplicates and merge them
    const processedItems = new Set();
    
    itemSections.forEach(({ itemId, section, quantity }) => {
      if (processedItems.has(itemId)) {
        // This is a duplicate - remove it
        section.remove();
      } else {
        // This is the first occurrence - update quantity to merged total
        const quantityInput = section.find('input[name*="[quantity]"]');
        quantityInput.val(itemQuantities[itemId]);
        processedItems.add(itemId);
      }
    });
  }
});