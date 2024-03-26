# Pin npm packages by running ./bin/importmap

pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.6.1/dist/jquery.js", preload: true
pin "admin-lte", to: "adminlte.js", preload: true
pin "application", preload: true
pin "startup", to: "startup.js", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulusloading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/utils", under: "utils"
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "popper", to: "popper.js", preload: true
pin "highcharts", to: "https://ga.jspm.io/npm:highcharts@10.3.2/highcharts.js"
pin "select2", to: "https://cdn.jsdelivr.net/npm/select2@4.0.13/dist/js/select2.min.js"
pin "trix", to: "https://ga.jspm.io/npm:trix@2.0.4/dist/trix.esm.min.js"
pin "@rails/actiontext", to: "https://ga.jspm.io/npm:@rails/actiontext@7.0.4/app/assets/javascripts/actiontext.js"
pin "luxon", to: "https://ga.jspm.io/npm:luxon@1.28.0/build/cjs-browser/luxon.js"
pin "litepicker", to: "https://cdn.jsdelivr.net/npm/litepicker/dist/litepicker.js"
pin "litepicker/ranges", to: "https://cdn.jsdelivr.net/npm/litepicker/dist/plugins/ranges.js"
pin "toastr", to: "https://ga.jspm.io/npm:toastr@2.1.4/toastr.js"
pin "@fullcalendar/core", to: "https://ga.jspm.io/npm:@fullcalendar/core@6.0.1/index.js"
pin "preact", to: "https://ga.jspm.io/npm:preact@10.11.3/dist/preact.module.js"
pin "preact/compat", to: "https://ga.jspm.io/npm:preact@10.11.3/compat/dist/compat.module.js"
pin "preact/hooks", to: "https://ga.jspm.io/npm:preact@10.11.3/hooks/dist/hooks.module.js"
pin "@fullcalendar/luxon", to: "https://ga.jspm.io/npm:@fullcalendar/luxon@6.0.1/index.js"
pin "@fullcalendar/core/", to: "https://ga.jspm.io/npm:@fullcalendar/core@6.0.1/"
pin "@fullcalendar/daygrid", to: "https://ga.jspm.io/npm:@fullcalendar/daygrid@6.0.1/index.js"
pin "@fullcalendar/list", to: "https://ga.jspm.io/npm:@fullcalendar/list@6.0.1/index.js"
pin "quagga", to: "https://ga.jspm.io/npm:quagga@0.12.1/dist/quagga.min.js"
pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.0.4/lib/assets/compiled/rails-ujs.js", preload: true
# NOTE: This has been vendored into vendor/javascript because there isn't a JS module exported by this package
pin "filterrific", to: "filterrific.js"
pin "bootstrap-select", to: "https://ga.jspm.io/npm:bootstrap-select@1.13.18/dist/js/bootstrap-select.js"
pin "jquery-ui", to: "https://ga.jspm.io/npm:jquery-ui@1.13.2/ui/widget.js"
