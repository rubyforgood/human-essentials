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

import {DateTime} from "luxon";
import 'litepicker';
import { Calendar } from '@fullcalendar/core';
import luxonPlugin from '@fullcalendar/luxon'
import dayGridPlugin from '@fullcalendar/daygrid';
import listPlugin from '@fullcalendar/list';
import toastr from 'toastr';
import 'litepicker/ranges';

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

// This global variable tracks whether Litepicker is actively managing the date range input field.
// It prevents custom validation logic from interfering when Litepicker is in use.
window.isLitepickerActive = false;

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
        const which = button.classList.contains(".fc-prev-button") ? "Previous" : "Next";
        button.setAttribute("aria-label", `${which} period`);
      });
  }

  const rangeElement = document.getElementById("filters_date_range");
  if (!rangeElement) {
    return;
  }

  // isLitepickerActive is a window global and survives a page change. If the calendar was
  // open when the user navigated away there is no "hide" event, so the flag stays true and
  // the date-range controller's validation is skipped for the rest of the session. Reset it
  // whenever a picker is set up, which is once per page.
  window.isLitepickerActive = false;
  const today = DateTime.now();
  const startDate = new Date(rangeElement.dataset["initialStartDate"]);
  const endDate = new Date(rangeElement.dataset["initialEndDate"]);

  const picker = new Litepicker({
    element: rangeElement,
    plugins: ["ranges"],
    startDate: startDate,
    endDate: endDate,
    format: "MMMM D, YYYY",
    ranges: {
      customRanges: {
        Default: [
          today.minus({ months: 2 }).toJSDate(),
          today.plus({ months: 1 }).toJSDate(),
        ],
        "All Time": [
          today.minus({ years: 100 }).toJSDate(),
          today.plus({ years: 1 }).toJSDate(),
        ],
        Today: [today.toJSDate(), today.toJSDate()],
        Yesterday: [
          today.minus({ days: 1 }).toJSDate(),
          today.minus({ days: 1 }).toJSDate(),
        ],
        "Last 7 Days": [today.minus({ days: 6 }).toJSDate(), today.toJSDate()],
        "Last 30 Days": [
          today.minus({ days: 29 }).toJSDate(),
          today.toJSDate(),
        ],
        "This Month": [
          today.startOf("month").toJSDate(),
          today.endOf("month").toJSDate(),
        ],
        "Last Month": [
          today.minus({ months: 1 }).startOf("month").toJSDate(),
          today.minus({ month: 1 }).endOf("month").toJSDate(),
        ],
        "Last 12 Months": [
          today.minus({ months: 12 }).plus({ days: 1 }).toJSDate(),
          today.toJSDate(),
        ],
        "Prior Year": [
          today.startOf("year").minus({ years: 1 }).toJSDate(),
          today.minus({ year: 1 }).endOf("year").toJSDate(),
        ],
        "This Year": [
          today.startOf("year").toJSDate(),
          today.endOf("year").toJSDate(),
        ],
      },
    },
  });

  // litepicker docs aren't clear on how to register events
  // https://github.com/wakirin/Litepicker/issues/301
  // Litepicker renders its own previous/next month buttons with an icon and no text, so they
  // are announced as nothing. Name them each time the calendar is shown, because Litepicker
  // rebuilds the markup on every open.
  const nameMonthButtons = () => {
    document.querySelectorAll(".button-previous-month").forEach((el) => {
      el.setAttribute("aria-label", "Previous month");
    });
    document.querySelectorAll(".button-next-month").forEach((el) => {
      el.setAttribute("aria-label", "Next month");
    });
  };

  // Litepicker builds its DOM during construction, so name them once now as well as on
  // every open -- otherwise the buttons sit in the page unnamed until the user opens the
  // calendar, which is exactly when an audit or a screen reader would first meet them.
  nameMonthButtons();
  picker.on("render", nameMonthButtons);

  picker.on("show", () => {
    nameMonthButtons();
    window.isLitepickerActive = true;
  });

  picker.on("hide", () => {
    window.isLitepickerActive = false;
  });

  picker.setDateRange(startDate, endDate);
});
