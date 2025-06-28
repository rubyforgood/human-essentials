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
    unless reminder_schedule.no_fields_filled_out? || (reminder_schedule.valid? && deadline_not_on_reminder_date?)
      errors.merge!(reminder_schedule.errors)
    end
  end

  def deadline_not_on_reminder_date?
    if reminder_schedule.day_of_month.to_i == deadline_day.to_i
      errors.add(:day_of_month, "Reminder day must not be the same as deadline day")
    end
  end
end
