module Deadlinable
  extend ActiveSupport::Concern
  MIN_DAY_OF_MONTH = 1
  MAX_DAY_OF_MONTH = 28

  included do
    validates :deadline_day, numericality: {only_integer: true, less_than_or_equal_to: MAX_DAY_OF_MONTH,
                                            greater_than_or_equal_to: MIN_DAY_OF_MONTH, allow_nil: true}
    validate :reminder_on_deadline_day?
    validate :reminder_schedule_is_within_range?
  end

  def convert_to_reminder_schedule(day)
    schedule = IceCube::Schedule.new
    schedule.add_recurrence_rule IceCube::Rule.monthly.day_of_month(day)
    schedule.to_ical
  end

  private

  def reminder_on_deadline_day?
    if reminder_schedule.nil?
      return
    end

    schedule = IceCube::Schedule.from_ical reminder_schedule
    if schedule.first.day == deadline_day
      errors.add(:reminder_schedule, "Reminder must not be the same as deadline date")
    end
  end

  def reminder_schedule_is_within_range?
    if reminder_schedule.nil?
      return
    end
    schedule = IceCube::Schedule.from_ical reminder_schedule
    reminder_day = schedule.first.day
    # IceCube converts negative or zero days to valid days (e.g. -1 becomes the last day of the month, 0 becomes 1)
    # The minimum check should no longer be necessary, but keeping it in case IceCube changes
    if reminder_day < 0 || reminder_day > MAX_DAY_OF_MONTH
      errors.add(:reminder_schedule, "Reminder day must be between #{MIN_DAY_OF_MONTH} and #{MAX_DAY_OF_MONTH}")
    end
  end
end
