// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready(function() {
  $(function() {
    function callback(start, end, label) {
      $('#filters_date_range').html(start.format('MMMM D, YYYY') + ' - ' + end.format('MMMM D, YYYY'));
      $('#filters_date_range_label').val(label);
    }

    $('#filters_date_range').daterangepicker({
        linkedCalendars: false,
        autoApply: true,
        ranges: {
           'All Time': [moment().subtract(100, 'years'), moment()],
           'Today': [moment(), moment()],
           'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
           'Last 7 Days': [moment().subtract(6, 'days'), moment()],
           'Last 30 Days': [moment().subtract(29, 'days'), moment()],
           'This Month': [moment().startOf('month'), moment().endOf('month')],
           'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')],
           'This Year': [moment().startOf('year'), moment().endOf('year')]
        }
    }, callback);

    start_date = $('#filters_date_range').data("initial-start-date");
    end_date = $('#filters_date_range').data("initial-end-date");
    $('#filters_date_range').data('daterangepicker').setStartDate(start_date);
    $('#filters_date_range').data('daterangepicker').setEndDate(end_date);
  });
});
