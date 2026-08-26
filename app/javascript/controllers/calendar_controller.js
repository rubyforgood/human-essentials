import { Controller } from "@hotwired/stimulus";
import { Calendar } from "@fullcalendar/core";
import luxonPlugin from "@fullcalendar/luxon";
import dayGridPlugin from "@fullcalendar/daygrid";
import listPlugin from "@fullcalendar/list";

/*
 * Owns the pick ups and deliveries calendar, and its toolbar.
 *
 * FullCalendar draws its own header, and it does not look like this app: three buttons filled
 * `rgb(44,62,80)` at a 4px radius and 16px text, next to a 28px/400 month title, on a page whose
 * only real action is a quiet secondary. The grid is restyled in CSS the way select2 is -- see
 * design.md -- but the toolbar is built here out of ordinary components instead, because three
 * buttons are cheap to own and owning them means a library upgrade cannot silently revert them.
 *
 * `headerToolbar: false` turns the library's version off. Everything the buttons need is public
 * API: `today()`, `prev()`, `next()`, and `datesSet` to hear where it landed.
 */
export default class extends Controller {
  static targets = ["grid", "title"];

  connect() {
    // Below 992px the month grid is unusable, so FullCalendar switches to its list view. Measured
    // on the window rather than a media query because the library wants the value at construction.
    const narrow = window.innerWidth < 992;
    const shortHeight = window.innerHeight < 768 && !narrow;

    this.calendar = new Calendar(this.gridTarget, {
      headerToolbar: false,
      timeZone: "UTC",
      firstDay: 1,
      plugins: [luxonPlugin, dayGridPlugin, listPlugin],
      displayEventTime: true,
      dayMaxEvents: true,
      events: "schedule.json",
      height: narrow || shortHeight ? "auto" : "parent",
      initialView: narrow ? "listWeek" : "dayGridMonth",
      // The heading is the only thing that says which month is on screen now that the library's
      // title is gone, and it is `aria-live` in the view so the change is announced.
      datesSet: (info) => {
        if (this.hasTitleTarget) this.titleTarget.textContent = info.view.title;
      }
    });

    this.calendar.render();
  }

  disconnect() {
    // Turbo can swap this away; without destroy the instance keeps its resize listeners.
    if (this.calendar) this.calendar.destroy();
  }

  today() {
    this.calendar.today();
  }

  previous() {
    this.calendar.prev();
  }

  next() {
    this.calendar.next();
  }
}
