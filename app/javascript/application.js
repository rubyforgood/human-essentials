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

import { Calendar } from '@fullcalendar/core';
import luxonPlugin from '@fullcalendar/luxon'
import dayGridPlugin from '@fullcalendar/daygrid';
import listPlugin from '@fullcalendar/list';
import toastr from 'toastr';

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

// Global toastr options
window.toastr = toastr;
toastr.options = {
  "timeOut": "1400"
}

function isMobileResolution() {
  return $(window).width() < 992;
}

function isShortHeightScreen() {
  return $(window).height() < 768 && !isMobileResolution();
}

$(document).ready(function(){
  // Opening a tab named by the URL fragment now lives in the tabs Stimulus controller. The
  // call here was `.tab("show")` -- Bootstrap's jQuery plugin, which is not loaded, so it
  // threw a TypeError on any page reached with a fragment.
  const isMobile = isMobileResolution();
  const isShortHeight = isShortHeightScreen();

  const calendarElement = document.getElementById("calendar");
  if (calendarElement) {
    // FullCalendar's prev/next buttons are icon-only with no text, so they are announced as
    // nothing. buttonHints names them; the aria-label pass covers the older markup too.
    const calendar = new Calendar(calendarElement, {
      buttonHints: {
        prev: "Previous $0",
        next: "Next $0",
        today: "This $0"
      },
      timeZone: "UTC",
      firstDay: 1,
      plugins: [luxonPlugin, dayGridPlugin, listPlugin],
      displayEventTime: true,
      eventLimit: true,
      events: "schedule.json",
      height: isMobile || isShortHeight ? "auto" : "parent",
      defaultView: isMobile ? "listWeek" : "month",
    });
    calendar.render();

    // Belt and braces: buttonHints is honoured by newer FullCalendar builds, but the
    // rendered chrome is the library's, so name anything it left bare.
    calendarElement.querySelectorAll(".fc-prev-button, .fc-next-button, .fc-today-button")
      .forEach((button) => {
        if (button.textContent.trim() || button.getAttribute("aria-label")) return;
        // classList.contains takes a bare token; with the leading dot it is always false, so
        // every unnamed button here was announced as "Next period" -- including Today.
        const label = button.classList.contains("fc-prev-button") ? "Previous period"
          : button.classList.contains("fc-next-button") ? "Next period"
            : "Today";
        button.setAttribute("aria-label", label);
      });
  }
});
