import $ from 'jquery';

/**
 * Likely we can remove this since distribution_and_transfers.js seen to cover this use
 */
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
    e) {
    const control = $(control_id);
    const insertedItem = $(e.detail[2]);
    insertedItem
      .find("#_barcode-lookup-new_line_items")
      .attr("id", `_barcode-lookup-${$(".nested-fields").length - 1}`);
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
