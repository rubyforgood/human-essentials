module ReminderScheduleable
  extend ActiveSupport::Concern

  included do
    # Consider prefixing the REMINDER_SCHEDULE_FIELDS to avoid collisions elsewhere?
    before_save :save_reminder_schedule_definition
    after_save :reset_reminder_schedule_service 

    validate :reminder_schedule_is_valid?
    validates :deadline_day, numericality: {
    only_integer: true,
    less_than_or_equal_to: ReminderScheduleService::MAX_DAY_OF_MONTH,
    greater_than_or_equal_to: ReminderScheduleService::MIN_DAY_OF_MONTH,
    allow_nil: true
  }
  end

  # For now assume that you won't be setting individual fields.
  # You'll only be updating the ReminderScheduleService via saving an object with params.
  def every_nth_month = reminder_schedule&.every_nth_month
  def every_nth_month=(x)
    if reminder_schedule
      reminder_schedule.every_nth_month = x
    end
  end
  def start_date = reminder_schedule&.start_date
  def start_date=(x)
    if reminder_schedule
      reminder_schedule.start_date = x
    end
  end
  def by_month_or_week = reminder_schedule&.by_month_or_week
  def by_month_or_week=(x)
    if reminder_schedule
      reminder_schedule.by_month_or_week = x
    end
  end
  def day_of_month = reminder_schedule&.day_of_month
  def day_of_month=(x)
    if reminder_schedule
      reminder_schedule.day_of_month = x
    end
  end
  def day_of_week = reminder_schedule&.day_of_week
  def day_of_week=(x)
    if reminder_schedule
      reminder_schedule.day_of_week = x
    end
  end
  def every_nth_day = reminder_schedule&.every_nth_day
  def every_nth_day=(x)
    if reminder_schedule
      reminder_schedule.every_nth_day = x
    end
  end

  def reminder_schedule
    if reminder_schedule_definition.present?
      @reminder_schedule_service ||= ReminderScheduleService.from_ical(reminder_schedule_definition, self)      
    end
    @reminder_schedule_service ||= ReminderScheduleService.new(parent_object: self, start_date: Time.zone.today)
  end

  def reminder_schedule_from_params
    @reminder_schedule_service ||= ReminderScheduleService.new({
      parent_object: self,
      every_nth_month: every_nth_month,
      start_date: start_date,
      by_month_or_week: by_month_or_week,
      day_of_month: day_of_month,
      day_of_week: day_of_week,
      every_nth_day: every_nth_day,
    })
  end

  def save_reminder_schedule_definition
    self.reminder_schedule_definition = reminder_schedule_from_params.to_ical
  end

  private

  def reminder_schedule_is_valid?
    unless reminder_schedule_from_params.valid?
      errors.merge!(reminder_schedule_from_params.errors)
    end
  end

  def reset_reminder_schedule_service
    @reminder_schedule_service = nil
  end

end
