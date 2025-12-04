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
              <button type="button" class="close" data-dismiss="modal">
                <span>&times;</span>
              </button>
            </div>
            <div class="modal-body">
              <p>The following items have multiple barcode entries that will be merged:</p>
              <p><strong>${itemList}</strong></p>
              <p>Quantities will be added together. Do you want to continue?</p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
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
    
    // Handle confirm button
    $('#confirmMerge').on('click', function() {
      $('#duplicateItemsModal').modal('hide');
      
      // Change form action to force_update
      const currentAction = form.attr('action');
      const currentUrl = window.location.pathname;
      console.log('Current action:', currentAction);
      console.log('Current URL:', currentUrl);
      
      // Try to get audit ID from URL first, then from action
      let auditId;
      const urlMatch = currentUrl.match(/\/audits\/(\d+)/);
      const actionMatch = currentAction.match(/\/audits\/(\d+)/);
      
      if (urlMatch) {
        auditId = urlMatch[1];
      } else if (actionMatch) {
        auditId = actionMatch[1];
      } else {
        console.log('New audit - adding merge_duplicates field');
        // For new audits, add a hidden field to allow duplicates
        form.append('<input type="hidden" name="merge_duplicates" value="true">');
        form.trigger('submit');
        return;
      }
      
      console.log('Extracted audit ID:', auditId);
      const newAction = `/audits/${auditId}/force_update`;
      console.log('New action:', newAction);
      form.attr('action', newAction);
      
      // Submit form
      form.off('submit');
      console.log('Submitting form to:', form.attr('action'));
      form.trigger('submit');
    });
  }
});