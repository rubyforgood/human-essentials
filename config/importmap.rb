# Pin npm packages by running ./bin/importmap

pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.6.1/dist/jquery.js"
pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.1.0/dist/stimulus.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "admin-lte", to: "https://ga.jspm.io/npm:admin-lte@3.2.0/dist/js/adminlte.min.js"
pin "@oddcamp/cocoon-vanilla-js", to: "https://ga.jspm.io/npm:@oddcamp/cocoon-vanilla-js@1.1.3/index.js"
pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@4.6.2/dist/js/bootstrap.js"
pin "popper.js", to: "https://ga.jspm.io/npm:popper.js@1.16.1/dist/umd/popper.js"
