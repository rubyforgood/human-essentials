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
//= require react
//= require react_ujs
//= require components
//= require_tree .


window.setTimeout(function() {
    $(".alert").fadeTo(1000, 0).slideUp(1000, function(){
        $(this).remove(); 
    });
}, 2500);

// Global toastr options
toastr.options = {
  "timeOut": "1400"
}


$(document).on("click", '#awesomebutton', function(e){
    $('#newBarcode').modal('hide');
    toastr.success("Barcode Added to Inventory");
});
