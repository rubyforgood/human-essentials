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
    today = Time.current.day

    if partner.partner_group&.reminder_day_of_month == today && partner.partner_group&.deadline_day_of_month.present?
      reminder_day = partner.partner_group.reminder_day_of_month
      deadline_day = partner.partner_group.deadline_day_of_month
    elsif partner.organization.reminder_day == today && partner.organization.deadline_day.present?
      reminder_day = partner.organization.reminder_day
      deadline_day = partner.organization.deadline_day
    else
      # Edge case: The deadline receiver may differ if this mailer is enqueued before midnight and run after midnight
      # We'll want to know if we ever run into such an edge case.
      raise "Could not determine whether reminder and deadline are set on partner group or organization"
    end

    deadline = Date.current
    deadline = deadline.next_month if reminder_day >= deadline_day
    deadline.change(day: deadline_day)
  end
end
