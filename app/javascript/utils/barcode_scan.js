import $ from 'jquery';
import Quagga from 'quagga';

/*
 * The camera scanner behind the barcode glyph.
 *
 * Quagga renders a live <video> and a <canvas> into whatever element it is given as `target`, and
 * it used to be given the button: `target: "#barcode-scanner-btn"`. A 38px button with a camera
 * feed inside it is not 38px any more -- the icon was pushed 339px to the left of where it
 * belongs -- and on a successful read the old code called `.empty()` on that same button, which
 * deleted the glyph outright. Both survived a page refresh only because neither was persisted.
 *
 * Three call sites carried `id="barcode-scanner-btn"`, and a donation form renders two of them,
 * so the id was not unique and `#barcode-scanner-btn` resolved to whichever came first: pressing
 * the *dialog's* camera button drew the picture inside the *scan bar's* button. Nothing is wired
 * by id now. Each scanner is a `[data-barcode-scan]` region holding its own input, its button and
 * a `[data-barcode-viewport]` for the picture.
 */
$(document).ready(function () {
  const READERS = ['ean_reader', 'ean_8_reader', 'code_39_reader', 'code_39_vin_reader',
    'codabar_reader', 'upc_reader', 'upc_e_reader'];

  // How many agreeing frames before a read is believed. Kept from the original.
  const FRAMES = 20;

  let active = null;
  let frames = [];

  $(document).on('click', '.barcode-scanner', function (e) {
    // currentTarget, not target: the click lands on the <i> inside the button as often as not,
    // and the old code took e.target and then asked for its previous sibling -- which for the
    // icon is nothing at all, so a camera read had nowhere to write its result.
    const button = e.currentTarget;
    if (active && active.button === button) { stop(); return; }
    if (active) stop();
    start(button);
  });

  function region(button) {
    const root = button.closest('[data-barcode-scan]');
    if (!root) return null;
    const viewport = root.querySelector('[data-barcode-viewport]');
    const input = root.querySelector('input:not([type=hidden])');
    return viewport && input ? { button, viewport, input } : null;
  }

  function start(button) {
    const scope = region(button);
    if (!scope) return;

    if (!(navigator.mediaDevices && typeof navigator.mediaDevices.getUserMedia === 'function')) {
      // Silence here read as a dead button. It is not one -- the browser has no camera API.
      //
      // Almost always this is an insecure origin: browsers only expose `mediaDevices` over https
      // or on localhost, so reaching the app through a port forward or a tunnel on plain http
      // removes it. Saying which of the two it is saves the reader guessing.
      say(scope, window.isSecureContext
        ? 'This browser will not give the page a camera. Type the barcode instead.'
        : 'The camera needs a secure (https) connection. On a plain http address the browser ' +
          'will not offer it. Type the barcode instead.');
      return;
    }

    active = scope;
    frames = [];
    scope.viewport.textContent = '';
    scope.viewport.classList.remove('hidden');
    scope.button.setAttribute('aria-expanded', 'true');

    Quagga.onDetected(onDetected);
    Quagga.init({
      inputStream: {
        name: 'Live',
        type: 'LiveStream',
        numOfWorkers: navigator.hardwareConcurrency,
        target: scope.viewport
      },
      decoder: { readers: READERS }
    }, function (err) {
      if (err) {
        // This was `console.log(err); stop();` -- and `stop()` hides the viewport again, so a
        // camera that refuses to start looked exactly like a button that does nothing. Reported
        // as "clicking it does not trigger the camera", and the only trace was in the console.
        //
        // Every one of these is something the reader can act on, so each says what to do rather
        // than reporting the exception name.
        const message = {
          NotAllowedError: 'The browser blocked the camera. Allow camera access for this site in ' +
            'your browser settings, then try again.',
          NotFoundError: 'No camera found on this device. Type the barcode instead.',
          NotReadableError: 'The camera is in use by another application. Close it and try again.',
          OverconstrainedError: 'No camera on this device can be used for scanning. Type the ' +
            'barcode instead.',
          SecurityError: 'The camera needs a secure (https) connection. Type the barcode instead.',
          // Chromium reports a refused permission as NotSupportedError as often as NotAllowedError,
          // depending on whether the refusal came from the prompt or from the origin being
          // insecure. Both mean the same thing to the reader, so both get the same sentence.
          NotSupportedError: 'The browser will not give this page the camera. That is usually a ' +
            'blocked permission, or a plain http address -- the camera needs https.'
        }[err.name] || 'The camera could not be started. Type the barcode instead.';

        stop();
        say(scope, message);
        return;
      }
      Quagga.initialized = true;
      Quagga.start();
    });
  }

  // Show a sentence where the picture would have been. `role="status"` is already on the viewport,
  // so this is announced without stealing focus.
  function say(scope, message) {
    scope.viewport.textContent = message;
    scope.viewport.classList.remove('hidden');
  }

  function stop() {
    if (!active) return;
    const scope = active;
    active = null;
    try {
      Quagga.offDetected(onDetected);
      Quagga.stop();
    } catch (err) {
      // init failed or never started; there is nothing to tear down.
    }
    // Emptying the viewport is safe because the viewport is Quagga's and nothing else's. This is
    // the line that used to be `$("#barcode-scanner-btn").empty()`.
    scope.viewport.innerHTML = '';
    scope.viewport.classList.add('hidden');
    scope.button.setAttribute('aria-expanded', 'false');
  }

  function onDetected(result) {
    frames.push(result.codeResult.code);
    if (frames.length <= FRAMES - 1) return;

    const code = mostFrequent(frames);
    const input = active && active.input;
    stop();
    if (!input) return;

    input.value = code;
    input.focus();
    input.dispatchEvent(new Event('input', { bubbles: true }));

    // On a line item card, finish the job: the same keypress a handheld reader sends, which
    // utils/barcode_items.js is listening for. Not in the barcode dialog -- the field there is
    // the barcode being *created*, and looking it up is the thing that failed to find it.
    if (input.classList.contains('__barcode_item_lookup')) {
      $(input).trigger($.Event('keypress', { which: 13 }));
    }
  }

  function mostFrequent(values) {
    const counts = {};
    values.forEach(function (value) { counts[value] = (counts[value] || 0) + 1; });
    return Object.keys(counts).sort(function (a, b) { return counts[b] - counts[a]; })[0];
  }
});
