class ReminderDeadlineJob < ApplicationJob
  def perform
    if Flipper.enabled?(:reminders_active)
      organizations = Organization.needs_reminding

      organizations.includes(:partners).each do |organization|
        organization.partners.where(send_reminders: true).each do |partner|
          ReminderDeadlineMailer.notify_deadline(partner, organization).deliver_now
        end
      end
    end
  end
end
