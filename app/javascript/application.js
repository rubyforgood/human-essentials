// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import jQuery from "jquery";
window.jQuery = jQuery
window.$ = jQuery

import "startup"
import "jquery-ui"
import 'filterrific'
import("@hotwired/turbo-rails").then(({ Turbo }) => {
  // Disable turbo by default to avoid issues with turbolinks
  Turbo.session.drive = false
})

import "trix"
import "@rails/actiontext"

import 'controllers'

import 'utils/barcode_items'
import 'utils/barcode_scan'
import 'utils/distributions_and_transfers'
import 'utils/donations'
import 'utils/purchases'

import Rails from "@rails/ujs"
Rails.start()

// Initialize Active Storage
import * as ActiveStorage from "@rails/activestorage";
ActiveStorage.start();

// toastr is gone, along with its CDN pin. It had one caller left -- barcode_items/create.js.erb --
// and no styling on a design-system page: the essentials layouts load only tailwind.css, and no
// toastr CSS is in that build, so its container rendered `position: static` with no background,
// appended at the foot of the document. That message is a flash bar now, from the same partial the
// server-rendered strip uses. Anything wanting a transient pop-up should build one here.

// The `$(document).ready` block that lived here held two things and now holds neither: opening a
// tab named by the URL fragment, which is the tabs Stimulus controller's job, and building the
// calendar, which is `calendar_controller`'s. The tab call was `.tab("show")` -- Bootstrap's jQuery
// plugin, which is not loaded, so it threw a TypeError on any page reached with a fragment.
