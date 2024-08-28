module Deadlinable
  extend ActiveSupport::Concern
  MIN_DAY_OF_MONTH = 1
  MAX_DAY_OF_MONTH = 28
  EVERY_NTH_COLLECTION = [["First", 1], ["Second", 2], ["Third", 3], ["Fourth", 4]].freeze
  WEEK_DAY_COLLECTION = [["Sunday"], ["Monday", 1], ["Tuesday", 2], ["Wednesday", 3], ["Thursday", 4], ["Friday", 5], ["Saturday", 6]].freeze

  included do
    attr_accessor :every_n_months, :date_or_week_day, :date, :day_of_week, :every_nth_day
    attr_reader :every_nth_collection, :week_day_collection, :date_or_week_day_collection
    validates :deadline_day, numericality: {only_integer: true, less_than_or_equal_to: MAX_DAY_OF_MONTH,
                                            greater_than_or_equal_to: MIN_DAY_OF_MONTH, allow_nil: true}
    validate :reminder_on_deadline_day?, if: -> { every_n_months.present? }
    validate :reminder_is_within_range?, if: -> { every_n_months.present? }
    validates :date_or_week_day, inclusion: {in: %w[date week_day]}, if: -> { every_n_months.present? }
    validates :date, presence: true, if: -> { date_or_week_day == "date" && every_n_months.present? }
    validates :day_of_week, presence: true, if: -> { date_or_week_day == "week_day" && every_n_months.present? }, inclusion: {in: %w[1 2 3 4 5 6 7]}
    validates :every_nth_day, presence: true, if: -> { date_or_week_day == "week_day" && every_n_months.present? }, inclusion: {in: %w[1 2 3 4]}
  end

  def convert_to_reminder_schedule(day)
    schedule = IceCube::Schedule.new
    schedule.add_recurrence_rule IceCube::Rule.monthly.day_of_month(day)
    schedule.to_ical
  end

  def show_description(ical)
    schedule = IceCube::Schedule.from_ical(ical)
    schedule.recurrence_rules.first.to_s
  end

  def from_ical(ical)
    return if ical.blank?
    schedule = IceCube::Schedule.from_ical(ical)
    rule = schedule.recurrence_rules.first.instance_values
    date = rule["validations"][:day_of_month]&.first&.value
    self.every_n_months = rule["interval"]
    self.date_or_week_day = date ? "date" : "week_day"
    self.date = date
    self.day_of_week = rule["validations"][:day_of_week]&.first&.day,
      self.every_nth_day = rule["validations"][:day_of_week]&.first&.occ
  rescue
    nil
  end

  private

  def reminder_on_deadline_day?
    if date_or_week_day == "date" && date.to_i == deadline_day
      errors.add(:date, "Reminder must not be the same as deadline date")
    end
  end

  def reminder_is_within_range?
    # IceCube converts negative or zero days to valid days (e.g. -1 becomes the last day of the month, 0 becomes 1)
    # The minimum check should no longer be necessary, but keeping it in case IceCube changes
    if date_or_week_day == "date" && date.to_i < MIN_DAY_OF_MONTH || date.to_i > MAX_DAY_OF_MONTH
      errors.add(:date, "Reminder day must be between #{MIN_DAY_OF_MONTH} and #{MAX_DAY_OF_MONTH}")
    end
  end

  def create_schedule
    schedule = IceCube::Schedule.new(Time.zone.now.to_date)
    return nil if every_n_months.blank? || every_n_months.to_i.zero?
    if date_or_week_day == "date"
      schedule.add_recurrence_rule(IceCube::Rule.monthly(every_n_months.to_i).day_of_month(date.to_i))
    else
      schedule.add_recurrence_rule(IceCube::Rule.monthly(every_n_months.to_i).day_of_week(day_of_week.to_i => [every_nth_day.to_i]))
    end
    schedule.to_ical
  rescue
    nil
  end
end
