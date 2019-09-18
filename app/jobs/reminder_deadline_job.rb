class ReminderDeadlineJob
  include Sidekiq::Worker

  def perform
    if Flipper.enabled?(:reminders_active)
      organizations = Organization.where('reminder_day = ? and deadline_day is not null', Date.current.day)
      organizations.each do |organization|
        organization.partners.where(send_reminders: true).each do |partner|
          ReminderDeadlineMailer.notify_deadline(partner, organization).deliver_now
        end
      end
    end
  end
end