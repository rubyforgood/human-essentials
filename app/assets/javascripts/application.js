// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
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
//= require quagga
//= require bootstrap-datepicker
//= require_tree .


window.setTimeout(function() {
    // When the user is given an error message, we should not auto-hide it so that
    // they can fully read it and potentially copy/paste it into an issue.
    $(".alert").not(".alert-danger, .alert-warning").fadeTo(1000, 0).slideUp(1000, function(){
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

function order_by_occurrence(arr) {
    var counts = {};
    arr.forEach(function(value){
        if(!counts[value]) {
            counts[value] = 0;
        }
        counts[value]++;
    });

    return Object.keys(counts).sort(function(curKey,nextKey) {
        return counts[curKey] < counts[nextKey];
    });
  }

  function load_quagga(){
    if ($('#barcode-scanner').length > 0 && navigator.mediaDevices && typeof navigator.mediaDevices.getUserMedia === 'function') {

      var last_result = [];
      if (Quagga.initialized == undefined) {
        Quagga.onDetected(function(result) {
          var last_code = result.codeResult.code;
          last_result.push(last_code);
          if (last_result.length > 20) {
            code = order_by_occurrence(last_result)[0];
            last_result = [];
            Quagga.stop();
            $.ajax({
              type: "POST",
              url: '/products/get_barcode',
              data: { upc: code }
            });
          }
        });
      }

      Quagga.init({
        inputStream : {
          name : "Live",
          type : "LiveStream",
          numOfWorkers: navigator.hardwareConcurrency,
          target: document.querySelector('#barcode-scanner')
        },
        decoder: {
            readers : ['ean_reader','ean_8_reader','code_39_reader','code_39_vin_reader','codabar_reader','upc_reader','upc_e_reader']
        }
      },function(err) {
          if (err) { console.log(err); return }
          Quagga.initialized = true;
          Quagga.start();
      });

    }
  };
  $(document).on('turbolinks:load', load_quagga);
