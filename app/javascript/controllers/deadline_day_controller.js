import { Controller } from "@hotwired/stimulus"
import $ from 'jquery';

export default class extends Controller {
  static targets = [
    'everyNthMonth', 'byDayOfMonth', 'byDayOfWeek', 'dayOfMonthFields', 'dayOfMonth',
    'dayOfWeekFields', 'everyNthDay', 'dayOfWeek', 'deadlineDay', 'reminderText', 'deadlineText'
  ]

  sourceChange() {
    let reminder_day = null;
    let deadline_day = null;
    // TODO: Actually calculate teh reminder and deadline days
    if (this.byDayOfMonthTarget.checked && this.dayOfMonthTarget.value) {
      reminder_day = this.dayOfMonthTarget.value;
    }
    if (this.byDayOfWeekTarget.checked && this.everyNthDayTarget.value && (this.dayOfWeekTarget.value || this.dayOfWeekTarget === 0)) {
      reminder_day = "by week day";
    }
    if (reminder_day && this.deadlineDayTarget.value) {
      deadline_day = this.deadlineDayTarget.value;
    }

    if (reminder_day && deadline_day && reminder_day == deadline_day) {
      $(this.reminderTextTarget).removeClass('text-muted').addClass('text-danger');
      $(this.reminderTextTarget).text('Reminder day cannot be the same as deadline day.');
      $(this.deadlineTextTarget).text("");
    } else {
      $(this.reminderTextTarget).removeClass('text-danger').addClass('text-muted');
      $(this.reminderTextTarget).text(reminder_day ? `Your next reminder will be sent on ${reminder_day} ${"month"}.` : "");
      $(this.deadlineTextTarget).text(deadline_day ? `Your next deadline will be on ${deadline_day} ${"month"}.` : "");
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
