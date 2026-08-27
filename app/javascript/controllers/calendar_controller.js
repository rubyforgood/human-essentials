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
 * components instead, because a handful of buttons are cheap to own and owning them means a
 * library upgrade cannot silently revert them. `headerToolbar: false` turns the library's off.
 *
 * Three views, and each name means exactly one thing. That is the whole of the fix for a bug this
 * file shipped: Week used to mean a *grid* above 992px and a *list* below it, and below 992 the
 * list was also the default -- so Week arrived already pressed, `switchView` returned early, and
 * the button did nothing at all. Month worked, so only Week looked broken. The mapping was the
 * mistake rather than the threshold; a list is a third view, not a narrow rendering of a week.
 *
 * There is no Day view and that is a measurement, not an omission: over a year, 22 days had any
 * distribution at all, mean 1.9, and 13 of those held exactly one. A day view is twenty-four rows
 * of hour axis for a line and a half.
 *
 * Week is day cells rather than an hour axis, for the same kind of reason. A distribution has no
 * end column, so on a time grid every event is a zero-length block; and half the rows in a fresh
 * database sit at 00:00, because `db/seeds.rb` writes a date with no time, so a time grid would
 * stack missing data at midnight and present it as an appointment.
 */

const WIDE_ENOUGH_FOR_A_GRID = 992;

// The URL carries these names, not FullCalendar's, so a shared link does not inherit the library's
// vocabulary or break when it changes.
const VIEWS = {
  month: "dayGridMonth",
  week: "dayGridWeek",
  list: "listWeek"
};

export default class extends Controller {
  static targets = ["grid", "title", "viewButton", "monthSelect", "yearSelect", "stepButton",
                    "todayButton", "todayReason"];

  connect() {
    this.onPopState = this.applyViewFromUrl.bind(this);
    window.addEventListener("popstate", this.onPopState);

    const view = this.requestedView;

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
      height: this.heightFor(view),
      initialView: this.fullCalendarView(view),
      // The heading is the only thing naming the range now that the library's title is gone, and it
      // is `aria-live` in the view so moving through months is announced.
      datesSet: (info) => {
        if (this.hasTitleTarget) this.titleTarget.textContent = info.view.title;
        this.syncJumpTo(info.view.currentStart);
        this.markToday(info.view);
      }
    });

    this.calendar.render();
    this.markPressed(view);
    this.labelStepButtons(view);
  }

  disconnect() {
    window.removeEventListener("popstate", this.onPopState);
    // Turbo can swap this away; without destroy the instance keeps its resize listeners.
    if (this.calendar) this.calendar.destroy();
  }

  today() {
    if (this.todayIsShowing) return;
    this.calendar.today();
  }

  /*
   * Today is the only control on this toolbar that can already be at its destination. The page
   * opens on today, so on arrival it does nothing -- which is the state you meet it in, and a
   * control that does nothing when you meet it reads as broken.
   *
   * design.md settled this shape for pagination: a control that leads nowhere stays **drawn and
   * disabled**, because a control set that changes width moves a target out from under the cursor.
   * That argument is stronger here than there, because Today flips on *every* Prev and Next rather
   * than only at the ends -- hiding it would shift its neighbours constantly.
   *
   * `aria-disabled`, not `disabled`. FullCalendar's own toolbar does disable it -- measured on
   * 6.0.1, `disabled` is true while the view holds today and false once you leave -- but a real
   * `disabled` drops the button out of the tab order, so the toolbar's number of tab stops would
   * change as you navigate. That is the same moving-target defect, one level up. The reason rides
   * along as sr-only text, which design.md asks of every unavailable action.
   */
  markToday(view) {
    if (!this.hasTodayButtonTarget) return;

    // UTC, because the calendar runs in UTC -- this has to agree with the cell it tints, and a
    // local-time answer would disagree with it for part of the day.
    const now = new Date();
    const today = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
    const showing = today >= view.currentStart.getTime() && today < view.currentEnd.getTime();

    this.todayButtonTarget.setAttribute("aria-disabled", String(showing));
    if (this.hasTodayReasonTarget) {
      this.todayReasonTarget.textContent = showing ? ", you are already viewing today" : "";
    }
  }

  get todayIsShowing() {
    return this.hasTodayButtonTarget &&
      this.todayButtonTarget.getAttribute("aria-disabled") === "true";
  }

  previous() {
    this.calendar.prev();
  }

  next() {
    this.calendar.next();
  }

  /*
   * The month and year selects. Prev and Next move one step, so before this the only way to reach
   * March next year was seven clicks, and last December was five.
   *
   * Two native selects rather than one `<input type="month">`: the app deleted Litepicker in favour
   * of native inputs and the argument is unchanged, but `type="month"` is a picker only in Chrome
   * and Edge -- in desktop Firefox and Safari it degrades to a text box expecting "2026-08", which
   * is a worse control than a select and silently so.
   */
  jumpTo() {
    const year = Number(this.yearSelectTarget.value);
    const month = Number(this.monthSelectTarget.value);
    this.calendar.gotoDate(new Date(Date.UTC(year, month, 1)));
  }

  /*
   * The selects follow the calendar as well as drive it: Today, Prev, Next and a view change all
   * move the range, and a control reading August while the grid shows October is worse than no
   * control at all.
   *
   * `currentStart` is the first date of the visible range, so a week straddling two months names
   * the one it starts in -- pick March, land on the week of 23 February, and the selects say
   * February. That is the honest answer: the week really is mostly February.
   */
  syncJumpTo(start) {
    if (!this.hasMonthSelectTarget || !this.hasYearSelectTarget) return;

    const year = String(start.getUTCFullYear());
    this.ensureYearOption(year);
    this.yearSelectTarget.value = year;
    this.monthSelectTarget.value = String(start.getUTCMonth());
  }

  // The year list is bounded by the organization's own distributions, so Prev and Next can walk off
  // either end of it. Inserting the year keeps the control truthful instead of leaving it showing
  // whichever year happened to be first in the list.
  ensureYearOption(year) {
    const options = Array.from(this.yearSelectTarget.options);
    if (options.some((option) => option.value === year)) return;

    const successor = options.find((option) => Number(option.value) > Number(year));
    this.yearSelectTarget.add(new Option(year, year), successor ?? null);
  }

  /*
   * The choice lives in the URL, not in localStorage. design.md settled this for page tabs and the
   * argument is unchanged: it is how a view becomes something you can link to, bookmark and go back
   * from. It is also the only option that can answer "why does mine look different from yours".
   *
   * `pushState`, so Back really does return to the previous view -- `replaceState` would deliver the
   * first two thirds of that sentence and quietly not the last.
   *
   * The month on screen is deliberately *not* in the URL. Prev, Next and Today move the range
   * without touching it, so putting only the select's jumps there would make two thirds of the
   * page's navigation linkable and one third not. If position should be shareable it should be
   * shareable however you got there.
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
    this.calendar.setOption("height", this.heightFor(name));
    this.calendar.changeView(this.fullCalendarView(name));
    this.markPressed(name);
    this.labelStepButtons(name);
  }

  markPressed(name) {
    this.viewButtonTargets.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.calendarView === name));
    });
  }

  // Prev and Next move a month in the month view and a week in the other two, so one fixed
  // "Previous month" would be wrong in two views out of three. The visible word is still inside the
  // accessible name, which is what 2.5.3 asks.
  labelStepButtons(name) {
    const unit = name === "month" ? "month" : "week";
    this.stepButtonTargets.forEach((button) => {
      button.setAttribute("aria-label", `${button.dataset.calendarStep} ${unit}`);
    });
  }

  get requestedView() {
    const asked = new URL(window.location).searchParams.get("view");
    return VIEWS[asked] ? asked : this.defaultView;
  }

  get defaultView() {
    // A month grid on a phone is unreadable, so the default there is the list -- which is what this
    // page already fell back to before there was any choice about it. Month and Week are both still
    // offered there; they are squeezed, not broken, and now they both work.
    return this.narrow ? "list" : "month";
  }

  fullCalendarView(name) {
    return VIEWS[name] ?? VIEWS.month;
  }

  // A list is as tall as its contents; a grid fills the card, unless the window is too narrow for
  // filling it to be readable.
  heightFor(name) {
    if (name === "list") return "auto";
    return this.narrow ? "auto" : "parent";
  }

  get narrow() {
    return window.innerWidth < WIDE_ENOUGH_FOR_A_GRID;
  }
}
