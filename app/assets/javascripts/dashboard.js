// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(() =>
  $("#filters.submit-on-change select#filters_interval").on("change", function(
    e
  ) {
    this.form.submit();
  })
);
