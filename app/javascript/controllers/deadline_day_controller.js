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
    'everyNthMonth', 'byDayOfMonth', 'byDayOfWeek', 'dayOfMonthFields', 'dayOfMonth',
    'dayOfWeekFields', 'everyNthDay', 'dayOfWeek', 'deadlineDay', 'reminderText', 'deadlineText'
  ]

  sourceChange() {
    let reminder_date = null;
    let deadline_date = null;
    if (this.byDayOfMonthTarget.checked && this.dayOfMonthTarget.value) {
      const rule = new RRule({
        freq: RRule.MONTHLY,
        interval: parseInt(this.everyNthMonthTarget.value),
        bymonthday: parseInt(this.dayOfMonthTarget.value),
        count: 1,
      })
      reminder_date = rule.all()[0]
    }
    if (this.byDayOfWeekTarget.checked && this.everyNthDayTarget.value && (this.dayOfWeekTarget.value)) {
      const rule = new RRule({
        freq: RRule.MONTHLY,
        interval: parseInt(this.everyNthMonthTarget.value),
        byweekday: WEEKDAY_NUM_TO_OBJ[ parseInt(this.dayOfWeekTarget.value) ].nth( parseInt(this.everyNthDayTarget.value) ),
        wkst: RRule.SU,
        count: 1
      })
      reminder_date = rule.all()[0]
    }
    if (reminder_date && this.deadlineDayTarget.value) {
      deadline_date = new Date(reminder_date.getTime());
      if( deadline_date.getDate() >= parseInt(this.deadlineDayTarget.value)){
        deadline_date.setMonth( deadline_date.getMonth() + 1 )
      }
      deadline_date.setDate(parseInt(this.deadlineDayTarget.value))
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
        $(this.reminderTextTarget).text(reminder_date ? `Your next reminder will be sent on ${reminder_date.toDateString()}.` : "");
      }
      if (deadlineDay < 1 || deadlineDay > 28){
        $(this.deadlineTextTarget).removeClass('text-muted').addClass('text-danger');
        $(this.deadlineTextTarget).text("Deadline day must be between 1 and 28");
      } else {
        $(this.deadlineTextTarget).removeClass('text-danger').addClass('text-muted');
        $(this.deadlineTextTarget).text(deadline_date ? `Your next deadline will be on ${deadline_date.toDateString()}.` : "");
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
