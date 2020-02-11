// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready(function() {
  $("#filters .submit-on-change").on("change", function(e) {
    $(this).submit();
  });
});
