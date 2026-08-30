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

  // `hidden`, the class the rest of the app uses, rather than jQuery's inline display. The server
  // now renders the right one visible and the other three hidden -- see the donation form -- so
  // this only ever changes that in response to a choice. With `.show()`/`.hide()` the two
  // mechanisms disagreed: an inline style beats the class, so a field the server had correctly
  // hidden could be un-hidden by an inline `display: block` that outlived the next selection.
  const showIf = (selector, on) => $(selector).toggleClass("hidden", !on);

  function handleSourceSelection() {
    const selection = $(control_id + " option")
      .filter(":selected")
      .text();

    /**
    * Handles the dynamic form of Donations
    **/
    showIf(product_drive_container_id, selection === product_drive_text);
    showIf(product_drive_participant_container_id, selection === product_drive_text);
    showIf(donation_site_container_id, selection === donation_site_text);
    showIf(manufacturer_container_id, selection === manufacturer_text);
  };

  $(control_id).each(handleSourceSelection);

  $(document).on("change", control_id, handleSourceSelection);

  // A handler that renumbered each inserted row's own barcode field used to live here. There is
  // one scan field per card now, outside the rows, so there is nothing per row to renumber.

  // A large donation asks first. This was a raw `window.confirm` -- the only one in the app that
  // is not `data-confirm`, and therefore the only one the click interceptor cannot reach.
  //
  // `confirm()` is synchronous and a <dialog> is not, so the shape changes: always prevent the
  // submit, ask, and submit again if the answer is yes. `requestSubmit` rather than `submit`, so
  // the form's own validation and submit handlers still run.
  const large_donation_boundary = 100000;
  $(document).on("click", "form#new_donation button[type='submit']", function (e) {
    const form = e.target.closest("form");
    if (form.dataset.largeDonationConfirmed === "true") return;

    const large = $(".quantity").toArray()
      .map((q) => parseInt(q.value, 10))
      .find((quantity) => quantity > large_donation_boundary);
    if (large === undefined) return;

    e.preventDefault();
    window.essentialsConfirm({
      message: `${large} items is a large donation! Are you sure you want to submit?`,
      title: "That is a lot of items",
      label: "Submit donation"
    }).then((ok) => {
      if (!ok) return;
      form.dataset.largeDonationConfirmed = "true";
      form.requestSubmit(e.target);
      delete form.dataset.largeDonationConfirmed;
    });
  });
});
