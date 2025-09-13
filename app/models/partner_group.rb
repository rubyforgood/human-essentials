# == Schema Information
#
# Table name: partner_groups
#
#  id                           :bigint           not null, primary key
#  deadline_day                 :integer
#  name                         :string
#  reminder_day                 :integer
#  reminder_schedule_definition :string
#  send_reminders               :boolean          default(FALSE), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  organization_id              :bigint
#
class PartnerGroup < ApplicationRecord
  has_paper_trail

  belongs_to :organization
  has_many :partners, dependent: :nullify
  has_and_belongs_to_many :item_categories

  validates :name, presence: true, uniqueness: { scope: :organization }
  validates :deadline_day, presence: true, if: :send_reminders?
  validates :deadline_day, numericality: {
    only_integer: true,
    less_than_or_equal_to: ReminderScheduleService::MAX_DAY_OF_MONTH,
    greater_than_or_equal_to: ReminderScheduleService::MIN_DAY_OF_MONTH,
    allow_nil: true
  }
  validate :reminder_schedule_is_empty_or_valid?
  validate :reminder_schedule_present?, if: :send_reminders?

  before_save :save_reminder_schedule_definition

  def reminder_schedule
    if reminder_schedule_definition.present?
      @reminder_schedule_service ||= ReminderScheduleService.from_ical(reminder_schedule_definition)
    end
    @reminder_schedule_service ||= ReminderScheduleService.new(start_date: Time.zone.today)
  end

  def save_reminder_schedule_definition
    self.reminder_schedule_definition = reminder_schedule.to_ical
    @reminder_schedule_service = nil
  end

  def reminder_schedule_is_empty_or_valid?
    # The schedule shouldn't be validated if the user hasn't touched that form,
    # so if by_month_or_week is still the default (nil) assume the user didn't
    # intend to fill out that form and don't validate.
    if reminder_schedule.fields_filled_out? && reminder_schedule.by_month_or_week.present?
      if !reminder_schedule.valid?
        errors.merge!(reminder_schedule.errors)
      end
      if deadline_on_reminder_date?
        errors.add(:day_of_month, "Reminder day must not be the same as deadline day")
      end
    end
  end

  def reminder_schedule_present?
    unless reminder_schedule.valid? && !deadline_on_reminder_date?
      errors.add(:send_reminders, "Valid reminder schedule must be present if send_reminders is true")
    end
    if deadline_on_reminder_date?
      errors.add(:day_of_month, "Reminder day must not be the same as deadline day")
    end
  end

  def deadline_on_reminder_date?
    reminder_schedule.by_month_or_week == "day_of_month" && reminder_schedule.day_of_month.to_i == deadline_day.to_i
  end
end
