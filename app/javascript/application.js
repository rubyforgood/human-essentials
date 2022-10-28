// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

/**
 * Load all javascript needed to run the AdminLTE theme and
 * all the interactions.
 */
import jQuery from 'jquery'
window.jQuery = jQuery
window.$ = jQuery

import 'admin-lte'
import "@oddcamp/cocoon-vanilla-js";

console.log("Hello from importmap-rails!")
