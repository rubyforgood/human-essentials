import $ from 'jquery';

$(document).ready(function () {
  const container_selector = '.deadline-day-pickers';
  const reminder_selector = '.deadline-day-pickers__reminder-day';
  const deadline_selector = '.deadline-day-pickers__deadline-day';
  const reminder_container_selector = '.deadline-day-pickers__reminder-container';
  const deadline_container_selector = '.deadline-day-pickers__deadline-container';

  const reminder_text_selector = '.deadline-day-pickers__reminder-day-text';
  const deadline_text_selector = '.deadline-day-pickers__deadline-day-text';

  const server_validation_selector = '.invalid-feedback';

  function refresh_text(container) {
    const $container = $(container);
    const $reminder = $container.find(reminder_selector);
    const $deadline = $container.find(deadline_selector);
    const $reminder_text = $container.find(reminder_text_selector);
    const $deadline_text = $container.find(deadline_text_selector);

    const reminder_day = parseInt($reminder.val());
    const deadline_day = parseInt($deadline.val());
    const current_day = parseInt($container.data('current-day'));

    const current_month = $container.data('current-month');
    const next_month = $container.data('next-month');

    if (reminder_day) {
      $(container).find(reminder_container_selector).find(server_validation_selector).remove();

      if (reminder_day === deadline_day) {
        $reminder_text.removeClass('text-muted').addClass('text-danger');

        $reminder_text.text('Reminder day cannot be the same as deadline day.');
      } else {
        $reminder_text.removeClass('text-danger').addClass('text-muted');

        const next_reminder_month = (current_day >= reminder_day) ? next_month : current_month;
        $reminder_text.text(`Your next reminder will be sent on ${reminder_day} ${next_reminder_month}.`);
      }
    }

    if (deadline_day) {
      $(container).find(deadline_container_selector).find(server_validation_selector).remove();

      const next_deadline_month = (current_day >= deadline_day) ? next_month : current_month;
      $deadline_text.text(`Your next deadline will be on ${deadline_day} ${next_deadline_month}`);
    }
  }

  $(container_selector).each(function(_, container) {
    refresh_text(container);
  })

  $(document).on('input', [reminder_selector, deadline_selector], function(evt) {
    const target = evt.target;
    const $target = $(target);
    const $container = $target.closest(container_selector);

    const value = parseInt($target.val());

    const min = parseInt($container.data('min'));
    const max = parseInt($container.data('max'));

    if (value < min) {
      $target.val(max);
    } else if (value > max) {
      $target.val(min);
    }

    refresh_text($container);
  })
})
