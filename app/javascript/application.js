// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import jQuery from "jquery";
window.jQuery = jQuery
window.$ = jQuery

import "startup"
import "jquery-ui"
import 'admin-lte'
import 'filterrific'
import { Turbo } from "@hotwired/turbo-rails"
import "trix"
import "@rails/actiontext"
import "bootstrap-select"

import {DateTime} from "luxon";
import 'litepicker';
import { Calendar } from '@fullcalendar/core';
import luxonPlugin from '@fullcalendar/luxon'
import dayGridPlugin from '@fullcalendar/daygrid';
import listPlugin from '@fullcalendar/list';
import toastr from 'toastr';
import 'litepicker/ranges';

import 'popper'
import 'bootstrap'
import 'controllers'

import 'utils/barcode_items'
import 'utils/barcode_scan'
import 'utils/deadline_day_pickers'
import 'utils/distributions_and_transfers'
import 'utils/donations'
import 'utils/purchases'

import Rails from "@rails/ujs"
Rails.start()
// Disable turbo by default to avoid issues with turbolinks
Turbo.session.drive = false

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
    const hash = window.location.hash;
    if (hash) {
      $('ul.nav a[href="' + hash + '"]').tab('show');
    }
    const isMobile = isMobileResolution();
    const isShortHeight = isShortHeightScreen();

    const calendarElement = document.getElementById('calendar');
    if (calendarElement) {
      new Calendar(calendarElement, {
        timeZone: 'UTC',
        firstDay: 1,
        plugins: [luxonPlugin, dayGridPlugin, listPlugin],
        displayEventTime: true,
        eventLimit: true,
        events: 'schedule.json',
        height: isMobile || isShortHeight ? 'auto' : 'parent',
        defaultView: isMobile ? 'listWeek' : 'month'
      }).render();
    }

    const rangeElement = document.getElementById("filters_date_range");
    if (!rangeElement) {
      return;
    }
    const today = DateTime.now();
    const startDate = new Date(rangeElement.dataset["initialStartDate"]);
    const endDate = new Date(rangeElement.dataset["initialEndDate"]);

    const picker = new Litepicker({
      element: rangeElement,
      plugins: ['ranges'],
      startDate: startDate,
      endDate: endDate,
      format: "MMMM D, YYYY",
      ranges: {
        customRanges: {
          'All Time': [today.minus({ 'years': 100}).toJSDate(), today.toJSDate()],
          'Today': [today.toJSDate(), today.toJSDate()],
          'Yesterday': [today.minus({'days': 1}).toJSDate(), today.minus({'days': 1}).toJSDate()],
          'Last 7 Days': [today.minus({'days': 6}).toJSDate(), today.toJSDate()],
          'Last 30 Days': [today.minus({'days': 29}).toJSDate(), today.toJSDate()],
          'This Month': [today.startOf('month').toJSDate(), today.endOf('month').toJSDate()],
          'Last Month': [today.minus({'months': 1}).startOf('month').toJSDate(),
            today.minus({'month': 1}).endOf('month').toJSDate()],
          'This Year': [today.startOf('year').toJSDate(), today.endOf('year').toJSDate()]
        }
      }
    });
    picker.setDateRange(startDate, endDate);
});

