// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

/**
 * Load all javascript needed to run the AdminLTE theme and
 * all the interactions.
 */
import jQuery from 'jquery'
import 'admin-lte'
import "@oddcamp/cocoon-vanilla-js";
import { Turbo } from "@hotwired/turbo-rails"

window.jQuery = jQuery
window.$ = jQuery

// Disable turbo by default to avoid issues with turbolinks
Turbo.session.drive = false

console.log("Hello from importmap-rails!")


