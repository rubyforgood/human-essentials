import $ from 'jquery';

// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function new_option(item, selected) {
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

function populate_dropdowns(objects, inventory) {
  objects.each(function(_, element) {
    const selected = Number(
      $(element)
        .find(":selected")
        .val()
    );
    let options = "";
    $.each(inventory, function(index) {
      const item_id = Number(inventory[index].item_id);
      options += new_option(inventory[index], selected === item_id);
    });
    $(element)
      .find("option")
      .remove()
      .end()
      .append(options);
  });
}

function request_storage_location_and_populate_item(item_to_populate) {
  const control = $("select.storage-location-source");
  if (control.length > 0 && control.val() !== "") {
    return $.ajax({
      url: control
        .data("storage-location-inventory-path")
        .replace(":id", control.val()),
      dataType: "json",
      success(data) {
        return populate_dropdowns($(item_to_populate), data);
      }
    });
  }
};

$(function() {
  let control = $("select.storage-location-source");
  const storage_location_required =
    $("form.storage-location-required").length > 0;
  const default_item = $(".line-item-fields select");

  $(document).on("change", "select.storage-location-source", function() {
    const default_item = $(".line-item-fields select");
    control = $("select.storage-location-source");
    if (storage_location_required && !control.val()) {
      $("#__add_line_item").addClass("disabled");
    }
    if (storage_location_required && control.val()) {
      $("#__add_line_item").removeClass("disabled");
    }

    request_storage_location_and_populate_item(default_item);
  });

  $(document).on(
    "form-input-after-insert",
    "form.storage-location-required",
    function(e) {
      const insertedItem = $(e.detail);
      request_storage_location_and_populate_item($("select", insertedItem));
      insertedItem
        .find("input.__barcode_item_lookup")
        .attr("id", `_barcode-lookup-${$(".nested-fields").length - 1}`);
      control = $("select.storage-location-source");
      $.ajax({
        url: control
          .data("storage-location-inventory-path")
          .replace(":id", control.val()),
        dataType: "json",
        success(data) {
          return populate_dropdowns($("select", insertedItem), data);
        }
      });
    }
  );

  $(function() {
    if (storage_location_required && !control.val()) {
      $("#__add_line_item").addClass("disabled");
    }

    request_storage_location_and_populate_item(default_item);
  });
});
