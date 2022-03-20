# Mailer to send to partners of an organization a reminder about the deadline date.
class ReminderDeadlineMailer < ApplicationMailer
  def notify_deadline(partner)
    @partner = partner
    @organization = partner.organization
    @deadline_day = partner.partner_group&.deadline_day_of_month || @organization.deadline_day
    mail(to: @partner.email, subject: "#{@organization.name} Deadline Reminder")
  end
end
