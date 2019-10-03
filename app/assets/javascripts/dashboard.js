// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(() =>
  $("#filters.submit-on-change #dates_date_interval").on("change", function(
    e
  ) {
    this.form.submit();
  })
);
