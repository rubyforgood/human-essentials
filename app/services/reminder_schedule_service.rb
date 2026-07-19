class ReminderScheduleService
  MIN_DAY_OF_MONTH = 1
  MAX_DAY_OF_MONTH = 28
  EVERY_NTH_COLLECTION = [["First", 1], ["Second", 2], ["Third", 3], ["Fourth", 4], ["Last", -1]].freeze
  DAY_OF_WEEK_COLLECTION = [["Sunday", 0], ["Monday", 1], ["Tuesday", 2], ["Wednesday", 3], ["Thursday", 4], ["Friday", 5], ["Saturday", 6]].freeze
  NTH_TO_WORD_MAP = {
    1 => "First",
    2 => "Second",
    3 => "Third",
    4 => "Fourth",
    -1 => "Last"
  }.freeze

  # The list of fields which are part of the _deadline_day_fields.html.erb form
  REMINDER_SCHEDULE_FIELDS = [
    :by_month_or_week,
    :day_of_month,
    :day_of_week,
    :every_nth_day
  ].freeze

  attr_accessor(*ReminderScheduleService::REMINDER_SCHEDULE_FIELDS)

  include ActiveModel::Validations

  validates :by_month_or_week, inclusion: {in: %w[day_of_month day_of_week]}
  validates :day_of_month, if: -> { @by_month_or_week == "day_of_month" }, presence: true
  validate :day_of_month_is_within_range?, if: -> { @by_month_or_week == "day_of_month" }
  validate :day_of_week_is_within_range?, if: -> { @by_month_or_week == "day_of_week" }
  validate :every_nth_day_is_within_range?, if: -> { @by_month_or_week == "day_of_week" }

  def initialize(parameter_hash)
    @by_month_or_week = parameter_hash[:by_month_or_week]
    @day_of_month = parameter_hash[:day_of_month]
    @day_of_week = parameter_hash[:day_of_week]
    @every_nth_day = parameter_hash[:every_nth_day]
  end

  def self.from_ical(ical)
    if ical.blank?
      return
    end
    schedule = IceCube::Schedule.from_ical(ical)
    rule = schedule.recurrence_rules.first.instance_values
    if rule.blank?
      return
    end
    day_of_month = rule["validations"][:day_of_month]&.first&.value

    ReminderScheduleService.new({
      by_month_or_week: day_of_month ? "day_of_month" : "day_of_week",
      day_of_month: day_of_month,
      day_of_week: rule["validations"][:day_of_week]&.first&.day,
      every_nth_day: rule["validations"][:day_of_week]&.first&.occ
    })
  end

  def []=(key, val)
    send("#{key}=", val)
  end

  def assign_attributes(attrs)
    attrs.each { |key, val| self[key] = val }
  end

  def to_icecube_schedule
    unless valid?
      return nil
    end
    schedule = IceCube::Schedule.new
    if by_month_or_week == "day_of_month"
      schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_month(day_of_month.to_i))
    else
      schedule.add_recurrence_rule(IceCube::Rule.monthly.day_of_week(day_of_week.to_i => [every_nth_day.to_i]))
    end
    schedule
  end

  def to_ical
    to_icecube_schedule&.to_ical
  end

  def show_description
    to_icecube_schedule&.recurrence_rules&.first.to_s
  end

  def fields_filled_out?
    by_month_or_week.present? || day_of_month.present? || day_of_week.present? || every_nth_day.present?
  end

  def occurs_on?(date)
    to_icecube_schedule&.occurs_on?(date)
  end

  def next_occurrence
    to_icecube_schedule&.next_occurrence
  end

  private

  def day_of_month_is_within_range?
    # IceCube converts negative or zero days to valid days (e.g. -1 becomes the last day of the month, 0 becomes 1)
    # The minimum check should no longer be necessary, but keeping it in case IceCube changes
    if day_of_month.to_i < MIN_DAY_OF_MONTH || day_of_month.to_i > MAX_DAY_OF_MONTH
      errors.add(:day_of_month, "Reminder day must be between #{MIN_DAY_OF_MONTH} and #{MAX_DAY_OF_MONTH}")
    end
  end

  def day_of_week_is_within_range?
    unless day_of_week.present? && ([0, 1, 2, 3, 4, 5, 6].include? day_of_week.to_i)
      errors.add(:day_of_week, "Day of week must be one of #{DAY_OF_WEEK_COLLECTION}")
    end
  end

  def every_nth_day_is_within_range?
    unless every_nth_day.present? && ([1, 2, 3, 4, -1].include? every_nth_day.to_i)
      errors.add(:every_nth_day, "Every Nth day must be one of #{EVERY_NTH_COLLECTION}")
    end
  end
end
