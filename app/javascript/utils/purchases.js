import $ from 'jquery';

$(function() {
  const vendor_id = "#purchase_vendor_id";
  const create_new_vendor_text = "---Not Listed---";
  $(vendor_id).append(`<option value="">${create_new_vendor_text}</option>`);

  $(document).on("change", vendor_id, function(evt) {
    const selection = $(vendor_id + " option")
      .filter(":selected")
      .text();
    if (selection === create_new_vendor_text) {
      document.getElementById("new_vendor").click()
    }
  });
});
