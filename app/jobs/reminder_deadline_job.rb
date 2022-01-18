class ReminderDeadlineJob < ApplicationJob
  #
  # This job is triggered on production daily via running the
  # command `rails initiate_reminder_deadline_job` using the
  # [Heroku Scheduler](https://devcenter.heroku.com/articles/scheduler)
  #

  def perform
    remind_these_partners = Partners::FetchPartnersToRemindNowService.new.fetch

    remind_these_partners.each do |partner|
      ReminderDeadlineMailer.notify_deadline(partner).deliver_later
    end
  end
end
