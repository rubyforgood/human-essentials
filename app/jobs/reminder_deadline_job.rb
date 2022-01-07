class ReminderDeadlineJob < ApplicationJob
  def perform
    remind_these_partners = Partners::FetchPartnersToRemindNowService.new.fetch

    remind_these_partners.each do |partner|
      ReminderDeadlineMailer.notify_deadline(partner).deliver_later
    end
  end
end
