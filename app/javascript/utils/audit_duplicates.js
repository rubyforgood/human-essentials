import $ from 'jquery';

$(() => {
  $("button[name='save_progress']").on('click', function (e) {

    const form = $(this).closest('form');
    const itemCounts = {}; // Will look like: { "2": 3, "5": 1, "12": 2 }
    const itemNames = {}; // Will look like: { "2": "Item A", "5": "Item B", "12": "Item C" }

    form.find('select[name$="[item_id]"]').each(function() {
      const itemId = $(this).val();
      const itemText = $(this).find('option:selected').text();
      const barcodeValue = $(this).closest('.line_item_section').find('.__barcode_item_lookup').val();
      if (!itemId || itemText === "Choose an item") {
        return;
      }
      itemCounts[itemId] = (itemCounts[itemId] || 0) + 1;
      itemNames[itemId] = itemText;
    });
    
    // Check for duplicates
    const duplicates = Object.keys(itemCounts)
      .filter(itemId => itemCounts[itemId] > 1)
      .map(itemId => itemNames[itemId]);

    if (duplicates.length > 0) {
      // Show modal with duplicate items
      showDuplicateModal(duplicates, form);
    } else {
      // No duplicates, proceed normally
      form.trigger('submit');
    }
    e.preventDefault();
  });
  
  function showDuplicateModal(duplicateItems, form) {
    const itemList = duplicateItems.join(', ');
    const modalHtml = `
      <div class="modal fade" id="duplicateItemsModal" tabindex="-1">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">Duplicate Items Detected</h5>
              <button type="button" class="close" data-bs-dismiss="modal">
                <span>&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <p>The following items have multiple barcode entries that will be merged:</p>
              <p><strong>${itemList}</strong></p>
              <p>Quantities will be added together. Do you want to continue?</p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
              <button type="button" class="btn btn-primary" id="confirmMerge">Yes, Merge Items</button>
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
    
    // Handle cancel button
    $('#duplicateItemsModal .btn-secondary').on('click', function() {
      $('#duplicateItemsModal').modal('hide');
    });
    
    // Handle confirm button
    $('#confirmMerge').on('click', function() {
      $('#duplicateItemsModal').modal('hide');
      
      // Merge duplicate items before submitting
      mergeDuplicateItems(form);
      
      // Find and click the actual Save Progress button to preserve its behavior
      const saveProgressBtn = form.find('button[name="save_progress"]');
      if (saveProgressBtn.length > 0) {
        // Temporarily remove our event handler to avoid infinite loop
        saveProgressBtn.off('click');
        saveProgressBtn.click();
      } else {
        // Fallback: add hidden input and submit
        form.append('<input type="hidden" name="save_progress" value="Save Progress">');
        form.trigger('submit');
      }
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