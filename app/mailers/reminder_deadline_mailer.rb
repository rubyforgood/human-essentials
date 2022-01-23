# Mailer to send to partners of an organization a reminder about the deadline date.
class ReminderDeadlineMailer < ApplicationMailer
  def notify_deadline(partner)
    @partner = partner
    @organization = partner.organization
    @deadline = deadline_date(partner)

    mail(to: @partner.email, subject: "#{@organization.name} Deadline Reminder")
  end

  private

  def deadline_date(partner)
    date = DeadlineService.new(partner: partner).next_deadline

    return date if date

    # Edge case: The deadline receiver may differ if this mailer is enqueued before midnight and run after midnight
    # We'll want to know if we ever run into such an edge case.
    raise "Could not determine deadline for partner #{partner.id}"
  end
end
