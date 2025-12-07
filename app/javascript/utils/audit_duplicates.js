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
        return;
      }
      itemCounts[itemId] = (itemCounts[itemId] || 0) + 1;
      itemNames[itemId] = itemText;
      if (!itemQuantities[itemId]) itemQuantities[itemId] = [];
      itemQuantities[itemId].push({ qty: itemQuantity, barcode: barcodeValue });
    });
    
    // Remove rows with zero quantity or no item selected
    form.find('select[name$="[item_id]"]').each(function() {
      const itemId = $(this).val();
      const itemText = $(this).find('option:selected').text();
      const section = $(this).closest('.line_item_section');
      const quantityInput = section.find('input[name*="[quantity]"]');
      const itemQuantity = parseInt(quantityInput.val()) || 0;
      
      if (!itemId || itemText === "Choose an item" || itemQuantity === 0) {
        section.remove();
      }
    });
    
    // Check for duplicates
    const duplicates = Object.keys(itemCounts)
      .filter(itemId => itemCounts[itemId] > 1)
      .map(itemId => ({ name: itemNames[itemId], id: itemId }));

    if (duplicates.length > 0) {
      // Show modal with duplicate items
      showDuplicateModal(duplicates, itemQuantities, form, buttonName);
      e.preventDefault();
    } else {
      // No duplicates, let the form submit normally
      // Don't prevent default - let the button's natural submit behavior work
    }
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
        const barcodeLine = entry.barcode ? `<div style="font-size: 0.85em; color: #666; margin-top: 2px;">Barcode: ${entry.barcode}</div>` : '';
        if (i === 0) {
          return `<div style="padding: 8px; margin: 4px 0; background-color: #f8f9fa; border-left: 3px solid #6c757d;">${item.name} - Quantity: ${entry.qty}${barcodeLine}</div>`;
        } else {
          return `<div style="padding: 8px; margin: 4px 0; background-color: #fff3cd; border-left: 3px solid #ffc107;"><strong>⚠ Duplicate:</strong> ${item.name} - Quantity: ${entry.qty}${barcodeLine}</div>`;
        }
      }).join('');
      return `<div style="margin-bottom: 20px; padding: 10px; background-color: #f9f9f9; border: 1px solid #ddd; border-radius: 5px;">${rows}<div style="padding: 10px; margin: 10px 0 0 0; background-color: #d1ecf1; border: 2px solid #0c5460; border-radius: 4px; font-weight: bold;">✓ Merged Result - Quantity: ${total}</div></div>`;
    }).join('');
    const modalHtml = `
      <div class="modal fade" id="duplicateItemsModal" tabindex="-1">
        <div class="modal-dialog modal-dialog-scrollable">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">Duplicate Items Detected</h5>
              <button type="button" class="close" data-bs-dismiss="modal">
                <span>&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <p><strong>The following items have multiple entries:</strong></p>
              <div>${itemRows}</div>
              <p style="margin-top: 15px; padding: 10px; background-color: #f8f9fa; border-left: 3px solid #6c757d;">Choose <strong>Merge Items</strong> to combine quantities and continue, or <strong>Review Entries</strong> to go back and make changes.</p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Review Entries</button>
              <button type="button" class="btn btn-warning" id="confirmMerge">Merge Items</button>
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
    
    // Handle review button
    $('#duplicateItemsModal .btn-secondary').on('click', function() {
      $('#duplicateItemsModal').modal('hide');
    });
    
    // Handle confirm button
    $('#confirmMerge').on('click', function() {
      $('#duplicateItemsModal').modal('hide');
      
      // Merge duplicate items before submitting
      mergeDuplicateItems(form);
      
      // Create a hidden button with the appropriate name to ensure proper parameter submission
      const hiddenBtn = $(`<button type="submit" name="${buttonName}" style="display:none;"></button>`);
      form.append(hiddenBtn);
      
      // Click the hidden button to submit with the correct parameter
      hiddenBtn.click();
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