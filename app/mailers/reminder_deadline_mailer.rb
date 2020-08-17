# # Mailer to send to partners of an organization a reminder about the deadline date.
class ReminderDeadlineMailer < ApplicationMailer
  def notify_deadline(partner, organization)
    @partner = partner
    @organization = organization
    mail(from: @organization.from_email, to: @partner.email, subject: "#{@organization.name} Deadline Reminder")
  end
end
