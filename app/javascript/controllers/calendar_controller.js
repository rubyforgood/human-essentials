import { Controller } from "@hotwired/stimulus";
import { Calendar } from "@fullcalendar/core";
import luxonPlugin from "@fullcalendar/luxon";
import dayGridPlugin from "@fullcalendar/daygrid";
import listPlugin from "@fullcalendar/list";

/*
 * Owns the pick ups and deliveries calendar, its toolbar and its view.
 *
 * FullCalendar draws its own header, and it does not look like this app: three buttons filled
 * `rgb(44,62,80)` at a 4px radius and 16px text, next to a 28px/400 month title. The grid is
 * restyled in CSS the way select2 is -- see design.md -- but the toolbar is built from ordinary
 * components instead, because three buttons are cheap to own and owning them means a library
 * upgrade cannot silently revert them. `headerToolbar: false` turns the library's off.
 *
 * Two views, Month and Week. There is no Day view and that is a measurement, not an omission: over
 * a year, 22 days had any distribution at all, mean 1.9, and 13 of those held exactly one. A day
 * view is twenty-four rows of hour axis for a line and a half.
 *
 * Week is day cells rather than an hour axis, for the same kind of reason. A distribution has no
 * end column, so on a time grid every event is a zero-length block; and half the rows in a fresh
 * database sit at 00:00, because `db/seeds.rb` writes a date with no time, so a time grid would
 * stack missing data at midnight and present it as an appointment.
 */

const WIDE_ENOUGH_FOR_A_GRID = 992;

export default class extends Controller {
  static targets = ["grid", "title", "viewButton"];

  connect() {
    this.onPopState = this.applyViewFromUrl.bind(this);
    window.addEventListener("popstate", this.onPopState);

    this.calendar = new Calendar(this.gridTarget, {
      headerToolbar: false,
      timeZone: "UTC",
      firstDay: 1,
      plugins: [luxonPlugin, dayGridPlugin, listPlugin],
      displayEventTime: true,
      dayMaxEvents: true,
      events: "schedule.json",
      /*
       * FullCalendar renders "+2 more" as an `<a>` with no `href`, carrying `aria-expanded` and an
       * empty `aria-controls`. An anchor without an href has no role, and neither attribute is
       * allowed on a generic element -- axe reports it as `aria-allowed-attr`, CRITICAL. It found
       * this the moment `db:seed:calendar` created a day crowded enough to overflow.
       *
       * The behaviour is already right: measured, Enter and Space both open the popover. So it acts
       * like a button and only fails to say so, which is the same defect design.md records for
       * `add_element_button` -- except there the keys were broken too.
       */
      moreLinkDidMount: (info) => {
        info.el.setAttribute("role", "button");
        // Empty and therefore pointing at nothing; the popover it opens has no id to reference.
        info.el.removeAttribute("aria-controls");
      },
      height: this.narrow ? "auto" : "parent",
      initialView: this.fullCalendarView(this.requestedView),
      // The heading is the only thing naming the range now that the library's title is gone, and it
      // is `aria-live` in the view so moving through months is announced.
      datesSet: (info) => {
        if (this.hasTitleTarget) this.titleTarget.textContent = info.view.title;
      }
    });

    this.calendar.render();
    this.markPressed(this.requestedView);
  }

  disconnect() {
    window.removeEventListener("popstate", this.onPopState);
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

  /*
   * The choice lives in the URL, not in localStorage. design.md settled this for page tabs and the
   * argument is unchanged: it is how a view becomes something you can link to, bookmark and go back
   * from. It is also the only option that can answer "why does mine look different from yours".
   *
   * `pushState`, so Back really does return to the previous view -- `replaceState` would deliver the
   * first two thirds of that sentence and quietly not the last.
   */
  switchView(event) {
    const name = event.currentTarget.dataset.calendarView;
    if (name === this.requestedView) return;

    const url = new URL(window.location);
    url.searchParams.set("view", name);
    window.history.pushState({}, "", url);

    this.applyView(name);
  }

  applyViewFromUrl() {
    this.applyView(this.requestedView);
  }

  applyView(name) {
    this.calendar.changeView(this.fullCalendarView(name));
    this.markPressed(name);
  }

  markPressed(name) {
    this.viewButtonTargets.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.calendarView === name));
    });
  }

  // "month" and "week" rather than FullCalendar's own names: the URL is the shareable part, and it
  // should not carry the library's vocabulary or change if the library's changes.
  get requestedView() {
    return new URL(window.location).searchParams.get("view") === "week" ? "week" : this.defaultView;
  }

  get defaultView() {
    // A month grid on a phone is unreadable, so the default there is the week -- as a list, which is
    // what this page already fell back to before there was any choice about it.
    return this.narrow ? "week" : "month";
  }

  fullCalendarView(name) {
    if (name !== "week") return "dayGridMonth";
    return this.narrow ? "listWeek" : "dayGridWeek";
  }

  get narrow() {
    return window.innerWidth < WIDE_ENOUGH_FOR_A_GRID;
  }
}
