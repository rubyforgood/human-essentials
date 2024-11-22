import $ from 'jquery';

// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function newOption(item, selected) {
  if (selected == null) {
    selected = false;
  }
  let content = `<option value="${item.item_id}"`;
  if (selected) {
    content += " selected";
  }
  content += ">";
  content += item.item_name;
  if (
    $("select.storage-location-source").attr("id") !==
    "audit_storage_location_id"
  ) {
    content += ` (${item.quantity})`;
  }
  content += "</option>\n";
  return content;
};

// Workaround to refresh item dropdown results for select2.
function rerenderDropdown(element) {
  const oldScrollTop = element.data('select2').$results.scrollTop();
  element.select2('close').select2('open');
  element.data('select2').$results.scrollTop(oldScrollTop);
}

function populateDropdowns(objects, inventory) {
  objects.each(function(_, element) {
    const selected = Number(
      $(element)
        .find(":selected")
        .val()
    );
    let options = "";
    $.each(inventory, function(index) {
      const item_id = Number(inventory[index].item_id);
      options += newOption(inventory[index], selected === item_id);
    });
    $(element)
      .find("option")
      .remove()
      .end()
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
      return data
    }
  });
}

$(function() {
  let control = $("select.storage-location-source");
  let dropdownOptions = {};
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

    if (control.length > 0 && control.val() !== "") {
      fetchDropdownOptions(control)
        .then((data) => {
          dropdownOptions = data;
          populateDropdowns($(".line-item-fields select"), dropdownOptions);
        });
    }
  });

  // Populate newly added item fields with stored dropdown options
  $(document).on(
    "form-input-after-insert",
    "form.storage-location-required",
    function(e) {
      const insertedItem = $(e.detail);
      insertedItem
        .find("input.__barcode_item_lookup")
        .attr("id", `_barcode-lookup-${$(".nested-fields").length - 1}`);
      populateDropdowns($("select", insertedItem), dropdownOptions);
    }
  );

  $(function() {
    if (storage_location_required && !control.val()) {
      $("#__add_line_item").addClass("disabled");
    }

    // If on page load, a storage location has been selected,
    // fetch inventory and populate dropdown options.
    if (control.length > 0 && control.val() !== "") {
      fetchDropdownOptions(control)
        .then((data) => {
          dropdownOptions = data;
          populateDropdowns($(".line-item-fields select"), dropdownOptions);
        });
    }
  });
});
