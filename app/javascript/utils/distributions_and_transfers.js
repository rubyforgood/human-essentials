import $ from 'jquery';

// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function newOption(item, selectedValue, includeQuantity) {
  const text = includeQuantity ? item.item_name + ` (${item.quantity})` : item.item_name;
  const value = Number(item.item_id);
  const isSelected = selectedValue === value;
  return new Option(text, value, isSelected, isSelected);
};

// Workaround to refresh item dropdown results for select2.
function rerenderDropdown(element) {
  const oldScrollTop = element.data('select2').$results.scrollTop();
  element.select2('close').select2('open');
  element.data('select2').$results.scrollTop(oldScrollTop);
}

function populateDropdowns(objects, inventory) {
  if (!inventory) return;

  const includeQuantity = $("select.storage-location-source").attr("id") !== "audit_storage_location_id";

  objects.each(function(_, element) {
    const selectedValue = Number(
      $(element)
        .find(":selected")
        .val()
    );
    const options = inventory.map(item => newOption(item, selectedValue, includeQuantity));
    $(element)
      .empty()
      .append(options);
    // If this select element is currently open, the option list is
    // now stale and needs to be refreshed.
    if ($(element).data('select2')?.isOpen()) {
      rerenderDropdown($(element))
    }
  });
}

function fetchDropdownOptions(control) {
  return $.ajax({
    url: control
      .data("storage-location-inventory-path")
      .replace(":id", control.val()),
    dataType: "json",
    success(data) {
      return data;
    }
  });
}

function fetchAndPopulateDropdownOptions(control) {
  if (control.length > 0 && control.val() !== "") {
    return fetchDropdownOptions(control)
      .then((data) => {
        populateDropdowns($(".line-item-fields select"), data);
        return data;
      });
  }
}

$(function() {
  let control = $("select.storage-location-source");
  let dropdownOptions;
  const storage_location_required =
    $("form.storage-location-required").length > 0;

  // store and populate item dropdown options when storage location is chosen
  $(document).on("change", "select.storage-location-source", function() {
    control = $("select.storage-location-source");
    if (storage_location_required && !control.val()) {
      $("#__add_line_item").addClass("disabled");
    }
    if (storage_location_required && control.val()) {
      $("#__add_line_item").removeClass("disabled");
    }

    fetchAndPopulateDropdownOptions(control)?.then(data => {
      dropdownOptions = data;
    });
  });

  // Populate newly added item fields with stored dropdown options
  $(document).on(
    "form-input-after-insert",
    "form.storage-location-required",
    function(e) {
      const insertedItem = $(e.detail);
      populateDropdowns($("select", insertedItem), dropdownOptions);
      insertedItem
        .find("input.__barcode_item_lookup")
        .attr("id", `_barcode-lookup-${$(".nested-fields").length - 1}`);
    }
  );

  $(function() {
    if (storage_location_required && !control.val()) {
      $("#__add_line_item").addClass("disabled");
    }

    // If on page load a storage location has been selected, fetch inventory
    // and populate dropdown options.
    fetchAndPopulateDropdownOptions(control)?.then(data => {
      dropdownOptions = data;
    });
  });
});
