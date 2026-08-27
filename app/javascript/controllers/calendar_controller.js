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
 * TWO AXES, and that is the whole shape of this file. How long -- a month or a week -- and how it
 * looks: a grid or a list. They are separate questions and they used to share one row of three
 * buttons, Month / Week / List, which could not answer either cleanly:
 *
 *   - "List" named a *shape* where its neighbours named a *duration*, so nothing said how much time
 *     it covered. Measured, the list is a week; the week of 7 September drew a single row.
 *   - Before that it was worse: "Week" meant a grid above 992px and a list below, and since the
 *     list was also the narrow default, Week arrived already pressed and its button did nothing.
 *
 * Both were the same mistake at different depths -- one label trying to carry two answers.
 * FullCalendar had the model right all along: its own toolbar labels these by duration, because a
 * list is a rendering of a range rather than a range.
 *
 * Splitting them also reaches `listMonth`, a whole month as one list, which three buttons could not
 * express at all.
 *
 * There is no Day view and that is a measurement, not an omission: over a year, 22 days had any
 * distribution at all, mean 1.9, and 13 of those held exactly one.
 *
 * Week is day cells rather than an hour axis, for a related reason. A distribution has no end
 * column, so on a time grid every event is a zero-length block; and half the rows in a fresh
 * database sit at 00:00, because `db/seeds.rb` writes a date with no time, so a time grid would
 * stack missing data at midnight and present it as an appointment.
 */

const WIDE_ENOUGH_FOR_A_GRID = 992;
const MS_PER_DAY = 86400000;

// The URL carries "month"/"week" and "grid"/"list", not FullCalendar's names, so a shared link does
// not inherit the library's vocabulary or break when it changes.
//
// The second parameter is `layout` rather than the obvious `format`, because **`format` is reserved
// by Rails routing** -- it is the response MIME type. `?format=grid` reached the controller as a
// request for a "grid" representation and the action raised `ActionController::UnknownFormat`, a
// 406, before rendering anything at all.
const VIEWS = {
  "month:grid": "dayGridMonth",
  "month:list": "listMonth",
  "week:grid": "dayGridWeek",
  "week:list": "listWeek"
};

const RANGES = ["month", "week"];
const LAYOUTS = ["grid", "list"];

// `?view=` was the parameter before the switcher split in two. Links shared while it existed still
// open on what they meant: `week` was the grid, and `list` was a week rendered as a list.
const LEGACY_VIEWS = {
  month: { range: "month", layout: "grid" },
  week: { range: "week", layout: "grid" },
  list: { range: "week", layout: "list" }
};

export default class extends Controller {
  static targets = ["grid", "title", "caption", "rangeButton", "layoutButton",
                    "monthSelect", "yearSelect", "stepButton"];

  connect() {
    this.onPopState = this.applyFromUrl.bind(this);
    window.addEventListener("popstate", this.onPopState);

    const range = this.requestedRange;
    const layout = this.requestedLayout;

    this.calendar = new Calendar(this.gridTarget, {
      headerToolbar: false,
      timeZone: "UTC",
      firstDay: 1,
      plugins: [luxonPlugin, dayGridPlugin, listPlugin],
      displayEventTime: true,
      dayMaxEvents: true,
      /*
       * The two list views order a day heading differently -- `listWeek` leads with the weekday and
       * `listMonth` with the date -- and that is left alone, because it cannot be fixed from here.
       *
       * Tried: `listDayFormat` and `listDayAltFormat`, globally and then per view. Overriding the
       * primary at all makes the *alt* mirror it, so every heading renders its own date twice --
       * "Sunday | Sunday", or "August 26, 2026 | August 26, 2026". The library's own defaults are
       * the only pair that renders two different things. A heading that reads in a different order
       * is a smaller problem than one that says the same thing twice.
       */
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
      height: this.heightFor(layout),
      initialView: VIEWS[`${range}:${layout}`],
      // The heading is the only thing naming the range now that the library's title is gone, and it
      // is `aria-live` in the view so moving through months is announced.
      datesSet: (info) => {
        if (this.hasTitleTarget) this.titleTarget.textContent = info.view.title;
        this.syncJumpTo(info.view.currentStart);
        this.renderCaption();
      },
      // Events arrive after the range is set, so the caption's count is wrong until they do.
      eventsSet: () => this.renderCaption()
    });

    this.calendar.render();
    this.markPressed(range, layout);
    this.labelStepButtons(range);
  }

  disconnect() {
    window.removeEventListener("popstate", this.onPopState);
    // Turbo can swap this away; without destroy the instance keeps its resize listeners.
    if (this.calendar) this.calendar.destroy();
  }

  /*
   * Today does nothing while today is already on screen, and that is deliberate.
   *
   * It was dimmed with `aria-disabled` for a day, on the reasoning that design.md disables
   * pagination's ends when they lead nowhere. Reverted: that rule is about controls whose press
   * *costs* something -- a pointless navigation, a page reload -- and pressing Today here costs
   * nothing. `calendar.today()` on today is idempotent and free.
   *
   * The convention agrees. Google, Outlook, Apple Calendar and Notion all keep Today live, and the
   * accessibility case against disabled controls is aimed at ones that gate a task the reader is
   * trying to finish. Neither reading argues for dimming something this cheap.
   */
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
   * The month and year selects. Prev and Next move one step, so before these the only way to reach
   * March next year was seven clicks, and last December five.
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
   * What the list covers, and how much of it is empty.
   *
   * A list renders only the days that have something on them -- FullCalendar has no option for
   * drawing empty ones, confirmed against its list-view documentation -- so a week holding one
   * distribution draws one row, and one row is indistinguishable from "there is one distribution,
   * ever". Measured before this: the week of 7 September rendered a single line under a heading
   * that said "Sep 7 – 13".
   *
   * List only. In a grid the empty days are already on screen as empty cells, so the same sentence
   * would be restating the picture.
   */
  renderCaption() {
    if (!this.hasCaptionTarget) return;

    const showing = this.requestedLayout === "list";
    this.captionTarget.hidden = !showing;
    if (!showing || !this.calendar) return;

    const view = this.calendar.view;
    const start = view.currentStart;
    const end = view.currentEnd;
    const total = Math.round((end - start) / MS_PER_DAY);

    const days = new Set();
    this.calendar.getEvents().forEach((event) => {
      if (!event.start || event.start < start || event.start >= end) return;
      days.add(event.start.toISOString().slice(0, 10));
    });

    this.captionTarget.textContent =
      `${this.rangeLabel(start, end)} · ${this.emptiness(days.size, total)}`;
  }

  rangeLabel(start, end) {
    if (this.requestedRange === "month") {
      return this.dateFormat({ month: "long", year: "numeric" }).format(start);
    }

    // `currentEnd` is exclusive, so the last day on screen is the day before it.
    const last = new Date(end.getTime() - MS_PER_DAY);

    /*
     * `formatRange`, not two `format` calls joined by a dash. It drops the parts the two ends share
     * -- "Monday, August 24 – Sunday, 30" rather than repeating August -- and it does so per locale
     * rather than by a rule written here.
     *
     * The first attempt asked for `{weekday, day}` on the near end and added the month only when
     * the range crossed one. Intl has no sensible pattern for a weekday and a bare day, and en-US
     * rendered it "24 Monday – Sunday, August 30".
     */
    return this.dateFormat({ weekday: "long", month: "long", day: "numeric" })
      .formatRange(start, last);
  }

  dateFormat(options) {
    return new Intl.DateTimeFormat(document.documentElement.lang || "en",
      { timeZone: "UTC", ...options });
  }

  emptiness(withEvents, total) {
    if (withEvents === 0) return `nothing scheduled in these ${total} days`;
    if (withEvents === 1) return `1 of ${total} days has a distribution`;
    return `${withEvents} of ${total} days have distributions`;
  }

  switchRange(event) {
    this.switchTo("range", event.currentTarget.dataset.calendarRange);
  }

  switchLayout(event) {
    this.switchTo("layout", event.currentTarget.dataset.calendarLayout);
  }

  /*
   * The choice lives in the URL, not in localStorage. design.md settled this for page tabs and the
   * argument is unchanged: it is how a view becomes something you can link to, bookmark and go back
   * from. It is also the only option that can answer "why does mine look different from yours".
   *
   * `pushState`, so Back really does return to the previous view -- `replaceState` would deliver the
   * first two thirds of that sentence and quietly not the last.
   *
   * *Both* parameters are written even though only one changed, so a shared link carries the whole
   * answer. Writing only the axis that moved would leave the other to a default that depends on the
   * reader's window width -- which is the sender's view on the sender's screen, and something else
   * on the recipient's.
   *
   * The month on screen is deliberately not in the URL. Prev, Next and Today move the range without
   * touching it, so putting only the select's jumps there would make two thirds of the page's
   * navigation linkable and one third not.
   */
  switchTo(axis, value) {
    const current = axis === "range" ? this.requestedRange : this.requestedLayout;
    if (value === current) return;

    const url = new URL(window.location);
    url.searchParams.set("range", axis === "range" ? value : this.requestedRange);
    url.searchParams.set("layout", axis === "layout" ? value : this.requestedLayout);
    url.searchParams.delete("view");
    window.history.pushState({}, "", url);

    this.apply();
  }

  applyFromUrl() {
    this.apply();
  }

  apply() {
    const range = this.requestedRange;
    const layout = this.requestedLayout;

    this.calendar.setOption("height", this.heightFor(layout));
    this.calendar.changeView(VIEWS[`${range}:${layout}`]);
    this.markPressed(range, layout);
    this.labelStepButtons(range);
    this.renderCaption();
  }

  markPressed(range, layout) {
    this.rangeButtonTargets.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.calendarRange === range));
    });
    this.layoutButtonTargets.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.calendarLayout === layout));
    });
  }

  // Prev and Next step whatever the *duration* is, so their names follow the range and not the
  // shape. The visible word stays inside the accessible name, which is what 2.5.3 asks.
  labelStepButtons(range) {
    this.stepButtonTargets.forEach((button) => {
      button.setAttribute("aria-label", `${button.dataset.calendarStep} ${range}`);
    });
  }

  get params() {
    return new URL(window.location).searchParams;
  }

  get requestedRange() {
    const asked = this.params.get("range");
    if (RANGES.includes(asked)) return asked;

    const legacy = LEGACY_VIEWS[this.params.get("view")];
    if (legacy) return legacy.range;

    // A month grid on a phone is unreadable, so a narrow window opens on the week.
    return this.narrow ? "week" : "month";
  }

  get requestedLayout() {
    const asked = this.params.get("layout");
    if (LAYOUTS.includes(asked)) return asked;

    const legacy = LEGACY_VIEWS[this.params.get("view")];
    if (legacy) return legacy.layout;

    // ...and as a list, which is what this page already fell back to before there was any choice
    // about it. Both grids are still offered there; they are squeezed, not broken.
    return this.narrow ? "list" : "grid";
  }

  // A list is as tall as its contents; a grid fills the card, unless the window is too narrow for
  // filling it to be readable.
  heightFor(layout) {
    if (layout === "list") return "auto";
    return this.narrow ? "auto" : "parent";
  }

  get narrow() {
    return window.innerWidth < WIDE_ENOUGH_FOR_A_GRID;
  }
}
