// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap.min
//= require fastclick
//= require adminlte.min
//= require cocoon
//= require toastr
//= require Chart.bundle
//= require chartkick
//= require moment
//= require fullcalendar
//= require_tree .


window.setTimeout(function() {
    // When the user is given an error message, we should not auto-hide it so that
    // they can fully read it and potentially copy/paste it into an issue.
    $(".alert").not(".alert-danger").fadeTo(1000, 0).slideUp(1000, function(){
        $(this).remove();
    });
}, 2500);

// Global toastr options
toastr.options = {
  "timeOut": "1400"
}

$( document ).ready(function() {
    $('#calendar').fullCalendar({
        firstDay: 1,
        displayEventTime : false,
        events: 'pick_ups.json'
    });
});
$(document).on("click", '#awesomebutton', function(e){
    /*
    $('#newBarcode').modal('hide');
    source_field = $('#trigger-field-id').val();

    // Clear out the fields, capturing the quantity and item_id
    item_id = $('#barcode_item_barcodeable_id').val();
    quantity = $('#barcode_item_quantity').val();
    $('#barcode_item_quantity').val('');
    $('#barcode_item_barcodeable_id').val('');
    $('#barcode_item_value').val('');
    $('#trigger-field-id').val('');

    // Notify the user
    toastr.success("Barcode Added to Inventory");

    // Locate the row where the barcode was entered from
    line_item = $('#' + source_field).closest('.nested-fields');
    // Set the values in the form. This is replicating some logic from barcode_items.js.erb
    $(line_item).find('input[type=number]').val(quantity);
    $(line_item).find('[value="' + item_id + '"]').attr("selected", true);
    $(line_item).parent().find('.nested-fields:last-child input.__barcode_item_lookup').focus();
    */
});
