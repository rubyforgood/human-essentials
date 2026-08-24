import $ from 'jquery';
$(document).ready(function() {
  /* Barcode readers will often "helpfully" send a CRLF at the end of the
     scanned string. We're going to capture this and use it to invoke the
     lookup method instead, since we don't want to submit the form just yet. */
  $(document).on('keypress', '.__barcode_item_lookup', capture_entry);

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
    if (!value) return;
    // Hardcoding magic URLs isn't ideal but it works for now
    $.getJSON("/barcode_items/find.json?barcode_item[value]=" + value, {}, function(data) {
         // Preserve this for reference of where we came from.
         data['src'] = src;
         data['value'] = value;
         // We're setting this here because if it's looked up as a global, we need to find the first local
         // item that matches.
         data['item_id'] = data['item']['id'];
         data['quantity'] = data['barcode_item']['quantity'];
         // Pass it all along to the .done() method
         return data;
      })
      .done(fill_fields_with_barcode_results)
      .fail(function(data) { prompt_for_new_barcode_item(data, value, src); } );
  }

  /**
  fill_fields_with_barcode_results
    @brief Puts the scanned item on a row. Event handler for above.
    @param data : JSON object result from the above method. Expecting a JSON-serialized BarcodeItem

    There is one scan field per card now, not one per row, so a scan no longer means "fill in the
    row I am standing in" -- there is no such row. It means: find the row this item is already on
    and add to it, or start a new one. That is what Square, Zoho and Odoo all do on a receiving
    screen, and it is why the field can keep focus and take the next scan immediately.

    The three-scan behaviour is kept from the previous version, which counted repeats by comparing
    the values left in each row's own barcode field: the first scan sets the barcode's quantity,
    the second adds it again, and the third and later ones ask how many packages there are in
    total. The count lives on the row as `data-scan-count` now, because the fields it used to be
    inferred from no longer exist.
  */
  function fill_fields_with_barcode_results(data) {
    const scope = $(data['src']).closest('fieldset');
    const container = scope.find('[data-capture-barcode="true"]').first();
    const itemId = String(data['item_id']);
    const perScan = Number(data['quantity']);

    let row = rowForItem(container, itemId);

    if (row) {
      const scans = Number($(row).attr('data-scan-count') || 1) + 1;
      const quantityField = $(row).find('[data-quantity]');
      const current = Number(quantityField.val()) || 0;

      if (scans >= 3) {
        const suggested = perScan ? Math.round(current / perScan) + 1 : 1;
        const packages = prompt('Enter total number of packages for this item', suggested);
        quantityField.val(packages === null ? current : Number(packages) * perScan);
      } else {
        quantityField.val(current + perScan);
      }
      $(row).attr('data-scan-count', scans);
    } else {
      row = emptyRow(container) || addRow(container);
      if (!row) return;
      // jQuery's trigger('change') is what select2 listens for; the native event below is what
      // anything using addEventListener sees. They are not the same dispatch.
      $(row).find('.line_item_name').val(itemId).trigger('change');
      $(row).find('[data-quantity]').val(perScan);
      $(row).attr('data-scan-count', 1);
      announce(row, '.line_item_name', 'change');
    }

    announce(row, '[data-quantity]', 'input');

    // Clear the field and keep the caret in it, so the next scan needs no click.
    $(data['src']).val('').trigger('focus');
  }

  /**
   * Fire a real DOM event, so listeners registered with addEventListener see the change.
   *
   * jQuery's .val() sets the property and .trigger() runs jQuery's own handler list -- neither
   * reaches a native listener, which is how the running total came to sit one scan behind the
   * quantity it was adding up.
   */
  function announce(row, selector, type) {
    const el = $(row).find(selector)[0];
    if (el) el.dispatchEvent(new Event(type, { bubbles: true }));
  }

  /** The visible, not-destroyed row already holding this item, if there is one. */
  function rowForItem(container, itemId) {
    let found = null;
    container.find('.line_item_section').each(function() {
      if (isDropped(this)) return undefined;
      const select = $(this).find('.line_item_name');
      if (select.length && String(select.val()) === itemId) {
        found = this;
        return false;
      }
    });
    return found;
  }

  /** A row nobody has chosen an item on yet -- the blank one a new form starts with. */
  function emptyRow(container) {
    let found = null;
    container.find('.line_item_section').each(function() {
      if (isDropped(this)) return undefined;
      const select = $(this).find('.line_item_name');
      if (select.length && !select.val()) {
        found = this;
        return false;
      }
    });
    return found;
  }

  function isDropped(row) {
    if (row.style.display === 'none') return true;
    const destroy = row.querySelector("input[name*='_destroy']");
    return Boolean(destroy && destroy.value === '1');
  }

  function addRow(container) {
    const button = document.getElementById('__add_line_item');
    if (!button) return null;
    button.click();
    return container.find('.line_item_section').last()[0] || null;
  }

  function prompt_for_new_barcode_item(data, value, src) {
    // Pre-fill the barcode field with the value
    $("#barcode_item_value").val(value);
    // Saving this to the modal so the modal knows which field to trigger when it's done.
    $("#trigger-field-id").val($(src).attr('id'));
    // Native <dialog>: Bootstrap modal JS is no longer loaded.
    document.getElementById("newBarcode")?.showModal();
    $("#barcode_item_quantity").focus();
  }
});
