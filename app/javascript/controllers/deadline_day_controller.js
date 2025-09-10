import { Controller } from "@hotwired/stimulus"
import $ from 'jquery';
import { RRule } from 'rrule'
import 'tslib'

const WEEKDAY_NUM_TO_OBJ = {
  0: RRule.SU,
  1: RRule.MO,
  2: RRule.TU,
  3: RRule.WE,
  4: RRule.TH,
  5: RRule.FR,
  6: RRule.SA
}

export default class extends Controller {
  static targets = [
    'byDayOfMonth', 'byDayOfWeek', 'dayOfMonthFields', 'dayOfMonth',
    'dayOfWeekFields', 'everyNthDay', 'dayOfWeek', 'deadlineDay', 'reminderText', 'deadlineText'
  ]

  static dateParser = /(\d{4})-(\d{2})-(\d{2})/;
  
  getFirstOccurrenceAfterToday( occurrences, today ) {
    let index = occurrences.length - 1
    let firstOccurrence = null
    while (index >= 0){
      if (occurrences[index].getTime() > today.getTime()) {
        firstOccurrence = occurrences[index]
        index--
      } else {
        break
      }
    }
    return firstOccurrence
  }

  sourceChange() {
    let reminder_date = null;
    let deadline_date = null;

    // For now, we are assuming that all schedules are monthly and start on the current date
    let monthlyInterval = 1;
    let today = new Date();
    let untilDate = new Date( today );
    untilDate.setMonth( untilDate.getMonth() + monthlyInterval + 1 )

    if (this.byDayOfMonthTarget.checked && this.dayOfMonthTarget.value) {
      const rule = new RRule({
        dtstart: today,
        freq: RRule.MONTHLY,
        interval: monthlyInterval,
        bymonthday: parseInt(this.dayOfMonthTarget.value),
        until: untilDate
      })
      reminder_date = this.getFirstOccurrenceAfterToday( rule.all(), today )
    }
    if (this.byDayOfWeekTarget.checked && this.everyNthDayTarget.value && (this.dayOfWeekTarget.value)) {
      const rule = new RRule({
        dtstart: today,
        freq: RRule.MONTHLY,
        interval: monthlyInterval,
        byweekday: WEEKDAY_NUM_TO_OBJ[ parseInt(this.dayOfWeekTarget.value) ].nth( parseInt(this.everyNthDayTarget.value) ),
        wkst: RRule.SU,
        until: untilDate
      })
      reminder_date = this.getFirstOccurrenceAfterToday( rule.all(), today )
    }
    if (reminder_date && this.deadlineDayTarget.value) {
      deadline_date = new Date(reminder_date.getTime());
      deadline_date.setDate(parseInt(this.deadlineDayTarget.value))
      if( reminder_date.getDate() >= parseInt(this.deadlineDayTarget.value)){
        deadline_date.setMonth( deadline_date.getMonth() + 1 )
      }
    }

    if (this.byDayOfMonthTarget.checked && this.dayOfMonthTarget.value
        && this.deadlineDayTarget.value && this.dayOfMonthTarget.value === this.deadlineDayTarget.value) {
      $(this.reminderTextTarget).removeClass('text-muted').addClass('text-danger');
      $(this.reminderTextTarget).text('Reminder day cannot be the same as deadline day.');
      $(this.deadlineTextTarget).text("");
    } else {
      let dayOfMonth = parseInt(this.dayOfMonthTarget.value);
      let deadlineDay = parseInt(this.deadlineDayTarget.value);
      if (dayOfMonth < 1 || dayOfMonth > 28){
        $(this.reminderTextTarget).removeClass('text-muted').addClass('text-danger');
        $(this.reminderTextTarget).text("Reminder day must be between 1 and 28");
      } else {
        $(this.reminderTextTarget).removeClass('text-danger').addClass('text-muted');
        $(this.reminderTextTarget).text(reminder_date ? `Your next reminder date is ${reminder_date.toDateString()}.` : "");
      }
      if (deadlineDay < 1 || deadlineDay > 28){
        $(this.deadlineTextTarget).removeClass('text-muted').addClass('text-danger');
        $(this.deadlineTextTarget).text("Deadline day must be between 1 and 28");
      } else {
        $(this.deadlineTextTarget).removeClass('text-danger').addClass('text-muted');
        $(this.deadlineTextTarget).text(deadline_date ? `The deadline on your next reminder email will be ${deadline_date.toDateString()}.` : "");
      }
    }
  }

  monthOrWeekChanged() {
    $(this.dayOfMonthFieldsTarget).toggleClass("d-none", !this.byDayOfMonthTarget.checked );
    $(this.dayOfWeekFieldsTarget).toggleClass("d-none", !this.byDayOfWeekTarget.checked );
  }

  connect() {
    this.monthOrWeekChanged()
    this.sourceChange()
  }
}
