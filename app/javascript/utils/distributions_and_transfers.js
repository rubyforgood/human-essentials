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
  });

  // Workaround for when a user opens a select2 dropdown and then an ajax
  // request changes the dropdown options while it is opened. In this case,
  // when an option is selected, we reselect that option in the new list
  // if the option exists in the new list of dropdown options.
  $("select.line_item_name").on('select2:select', function (e) {
    const selectedOption = e.params.data.id;

    $(e.target)
      .has(`option[value=${selectedOption}]`)
      .select2()
      .val(selectedOption)
      .trigger('change');
  });
});
