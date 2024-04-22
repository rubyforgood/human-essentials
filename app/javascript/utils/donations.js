import $ from 'jquery';
$(function() {
  const control_id = "#donation_source";

  const product_drive_participant_id = "#donation_product_drive_participant_id";
  const product_drive_id = "#donation_product_drive_id"
  const manufacturer_id = "#donation_manufacturer_id";

  const donation_site_container_id = "div.donation_donation_site";
  const product_drive_container_id = "div.donation_product_drive";
  const product_drive_participant_container_id = "div.donation_product_drive_participant";
  const manufacturer_container_id = "div.donation_manufacturer";

  const product_drive_text = "Product Drive";
  const manufacturer_text = "Manufacturer";
  const donation_site_text = "Donation Site";

  const create_new_product_drive_text = "---Create new Product Drive---";
  const create_new_product_drive_participant_text = "---Create new Participant---";

  const create_new_manufacturer_text = "---Create new Manufacturer---";

  $(product_drive_id).append(

    `<option value="">${create_new_product_drive_text}</option>`
  );
  $(product_drive_participant_id).append(
    `<option value="">${create_new_product_drive_participant_text}</option>`
  );

  $(manufacturer_id).append(
    `<option value="">${create_new_manufacturer_text}</option>`
  );

  $(document).on("change", product_drive_id, function(evt) {
    const selection = $(product_drive_id + " option")
      .filter(":selected")
      .text();
    if (selection === create_new_product_drive_text) {
      document.getElementById("new_product_drive").click()
    }
  });

  $(document).on("change", product_drive_participant_id, function(evt) {
    const selection = $(product_drive_participant_id + " option")
      .filter(":selected")
      .text();

    if (selection === create_new_product_drive_participant_text) {
      document.getElementById("new_participant").click()
    }
  });

  $(document).on("change", manufacturer_id, function(evt) {
    const selection = $(manufacturer_id + " option")
      .filter(":selected")
      .text();

    if (selection === create_new_manufacturer_text) {
      document.getElementById("new_manufacturer").click()
    }
  });

  function handleSourceSelection() {
    const selection = $(control_id + " option")
      .filter(":selected")
      .text();

    /**
    * Handles the dynamic form of Donations
    **/
    if (selection === product_drive_text) {
      $(product_drive_container_id).show();
      $(product_drive_participant_container_id).show();
      $(donation_site_container_id).hide();
      $(manufacturer_container_id).hide();
    } else if (selection === manufacturer_text) {
      $(manufacturer_container_id).show();
      $(product_drive_container_id).hide();
      $(product_drive_participant_container_id).hide();
      $(donation_site_container_id).hide();
    } else if (selection === donation_site_text) {
      $(product_drive_container_id).hide();
      $(product_drive_participant_container_id).hide();
      $(donation_site_container_id).show();
      $(manufacturer_container_id).hide();
    } else {
      $(product_drive_container_id).hide();
      $(product_drive_participant_container_id).hide();
      $(donation_site_container_id).hide();
      $(manufacturer_container_id).hide();
    }
  };

  $(control_id).each(handleSourceSelection);

  $(document).on("change", control_id, handleSourceSelection);

  $(document).on(
    "form-input-after-insert",
    "#donation_line_items",
    (e) => {
      const insertedItem = $(e.detail);
      insertedItem
        .find("input.__barcode_item_lookup")
        .attr("id", `_barcode-lookup-${$(".nested-fields").length - 1}`)
    }
  )

  const large_donation_boundary = 100000;
  $(document).on("submit", "form#new_donation", (e, _) =>
    $(".quantity").each(function(_, q) {
      const quantity = parseInt(q.value, 10);
      if (quantity > large_donation_boundary) {
        confirm(
          `${quantity} items is a large donation! Are you sure you want to submit?`
        );
      }
    })
  );
});
