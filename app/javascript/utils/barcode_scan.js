import $ from 'jquery';
import Quagga from 'quagga';

$(document).ready(function () {
  $(document).on('click', '.barcode-scanner',function(e) {
    var target = $(e.target)
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
        $("#barcode-scanner-btn").empty()
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
          target: "#barcode-scanner-btn"
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
