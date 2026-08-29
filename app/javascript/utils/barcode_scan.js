import $ from 'jquery';
import Quagga from 'quagga';

$(document).ready(function () {
  $(document).on('click', '.barcode-scanner',function(e) {
    // currentTarget, not target: the click can land on a child of the button, and load_quagga
    // needs the button itself so it can render the camera there and reach the field beside it.
    var target = $(e.currentTarget)
    load_quagga(target);

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
  function startScan(result) {
      var last_code = result.codeResult.code;
      last_result.push(last_code);
      if (last_result.length > 19) {
        const upc_code = order_by_occurrence(last_result)[0];

        // last_result = [];
        Quagga.stop();
        Quagga.offDetected(startScan);
        last_target.empty()
        last_target.prev().val(upc_code)
        }

  }
  function load_quagga(target){
    if (navigator.mediaDevices && typeof navigator.mediaDevices.getUserMedia === 'function') {
      window.last_result = [];
      window.last_target = target
      Quagga.onDetected(startScan);

      Quagga.init({
        inputStream : {
          name : "Live",
          type : "LiveStream",
          numOfWorkers: navigator.hardwareConcurrency,
          // The button that was clicked, not a shared id. `#barcode-scanner-btn` was hard-coded on
          // every line-item row and in the barcode modal, so it was never unique and Quagga always
          // drew the camera into the first one on the page -- never the modal's.
          target: target[0]
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
});
