import $ from 'jquery';
$(document).ready(function() {
  /* Barcode readers will often "helpfully" send a CRLF at the end of the
     scanned string. We're going to capture this and use it to invoke the
     lookup method instead, since we don't want to submit the form just yet. */
  $('[data-capture-barcode="true"]').on('keypress', '.__barcode_item_lookup', capture_entry);

  /**
  capture_entry
  @brief prevents the form from submitting and instead sends an XHR to lookup the barcode
  @param event : the keypress event object
  */
  function capture_entry(event) {
    if (event.which == '10' || event.which == '13') {
      barcode_item_lookup(event.target.value, event.target);
      event.preventDefault();
    }
  }

  /**
  barcode_item_lookup
   @brief Invokes an ajax lookup of a provided barcode value
   @param value : the barcode
   @param src : the DOM source, so we can callback to it.
   */
  function barcode_item_lookup(value, src) {
    // Hardcoding magic URLs isn't ideal but it works for now
    $.getJSON("/barcode_items/find.json?barcode_item[value]=" + value, {}, function(data) {
         // Preserve this for reference of where we came from.
         data['src'] = src;
         data['value'] = value;
         // We're setting this here because if it's looked up as a global, we need to find the first local
         // item that matches.
         data['item_id'] = data['item']['id'];
         data['quantity'] = data['barcode_item']['quantity'];
         console.log(data);
         // Pass it all along to the .done() method
         return data;
      })
      .done(fill_fields_with_barcode_results)
      .fail(function(data) { prompt_for_new_barcode_item(data, value, src); } )
      .always(function(data){
        // ...
    });
  }

  /**
  fill_fields_with_barcode_results
    @brief Sets the fields for the line item with the results. Event handler for above.
    @param data : JSON object result from the above method. Expecting a JSON-serialized BarcodeItem
  */
  function fill_fields_with_barcode_results(data) {
    let line_item = $(data['src']).closest('.nested-fields');
      let line_item_quantity = data['quantity'];
      $('.__barcode_item_lookup').each(function () {
          if (data['src'] != this && data['value'] == this.value) {
              line_item = this.closest('.nested-fields');
              if ($(line_item).attr('scanned_more_than_two_times') != undefined) {
                  let current_total = parseInt($(line_item).find('[data-quantity]').val());
                  let current_boops = (current_total / line_item_quantity) + 1;
                  let total_boops = prompt('Enter total number of packages for this item', current_boops);
                  if (total_boops != null) {
                      total_boops = parseInt(total_boops);
                      line_item_quantity = total_boops * line_item_quantity;
                  } else {
                      total_boops = 0;
                      line_item_quantity = 0;
                  }
              }
              if ($(line_item).attr('scanned_more_than_two_times') != "true") {
                line_item_quantity = Number(line_item_quantity) + Number($(line_item).find('[data-quantity]').val());
              }
              $(line_item).attr('scanned_more_than_two_times', true);
          }
      })
      $(line_item).find('[data-quantity]').val(line_item_quantity);
      $(line_item).find('select').val(data['item_id']);
      $(line_item).find('select').trigger('change');

      if ($(data['src']).closest('.nested-fields')[0] != $(line_item).closest('section')[0]) {
          $(data['src']).closest('.nested-fields').remove();
          $('.line-item-separator:last').remove();
      }
    // This will facilitate serial barcode inputs.
    // First trigger the "add new line item"
    document.getElementById('__add_line_item').click();
    // Now focus on the barcode field
    $("input.__barcode_item_lookup").last().focus();
  }

  function prompt_for_new_barcode_item(data, value, src) {
    // Pre-fill the barcode field with the value
    $("#barcode_item_value").val(value);
    // Saving this to the modal so the modal knows which field to trigger when it's done.
    $("#trigger-field-id").val($(src).attr('id'));
    new bootstrap.Modal('#newBarcode').show()
    $("#barcode_item_quantity").focus();
  }
});
