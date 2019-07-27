// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

const item_option = item => {
  return `<option value='${item.item_id}'> \
          ${item.item_name} -- ${item.quantity} \
          </option>`;
}

$(function() {
  const control_id = "#adjustment_storage_location_id";

  $(document).on("change", control_id, function(evt) {
    const control = $(evt.target);
    $.ajax({
      url: control
        .data("storage-location-inventory-path")
        .replace(":id", control.val()),
      dataType: "json",
      success(data) {
        const options = $.map(data, item_option);
        $("#adjustment_storage_location_line_items select").html(options);
      }
    });
  });

  $(document).on("cocoon:after-insert", "form#new_adjustment", function(
    e,
    insertedItem
  ) {
    const control = $(control_id);
    insertedItem
      .find("#_barcode-lookup-new_line_items")
      .attr("id", `_barcode-lookup-${$(".nested-fields").size() - 1}`);
    $.ajax({
      url: control
        .data("storage-location-inventory-path")
        .replace(":id", control.val()),
      dataType: "json",
      success(data) {
        const options = $.map(data, item_option);
        console.log("inserted item", insertedItem);
        $("select", insertedItem).html(options);
      }
    });
  });
});
