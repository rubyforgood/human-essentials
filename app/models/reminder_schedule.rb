class ReminderSchedule
  include ActiveModel::Model

  attr_accessor :every_n_months, :date_or_week_day, :date, :day_of_week, :every_nth_day
  attr_reader :every_nth_collection, :week_day_collection, :date_or_week_day_collection

  validates :every_n_months, presence: true, inclusion: 1..12
  validates :date_or_week_day, presence: true, inclusion: { in: %w[date week_day] }
  validates :date, presence: true, if: -> { date_or_week_day == 'date' }
  validates :day_of_week, presence: true, if: -> { date_or_week_day == 'week_day' }, inclusion: 1..7
  validates :every_nth_day, presence: true, if: -> { date_or_week_day == 'date' }, inclusion: 1..4


  def initialize(attributes = {})
    super
    @every_n_months = every_n_months.to_i
    @date = date.to_i
    @day_of_week = day_of_week.to_i
    @every_nth_day = every_nth_day.to_i
    @every_nth_collection = EVERY_NTH_COLLECTION
    @week_day_collection = WEEK_DAY_COLLECTION
    @date_or_week_day_collection = DATE_OR_WEEK_DAY_COLLECTION
  end

  def create_schedule
    binding.pry
    schedule = IceCube::Schedule.new(Time.zone.now.to_date)
    if date_or_week_day == 'date'
      schedule.add_recurrence_rule(IceCube::Rule.monthly(every_n_months).day_of_month(date))
    else
      schedule.add_recurrence_rule(IceCube::Rule.monthly(every_n_months).day_of_week(day_of_week => [every_nth_day]))
    end
    schedule.to_ical
  end

  def self.from_ical(ical)
    schedule = IceCube::Schedule.from_ical(ical)
    rule = schedule.recurrence_rules.first.instance_values
    date = rule["validations"][:day_of_month]&.first&.value
    new(
      every_n_months: rule['interval'],
      date_or_week_day: date ? 'date' : 'week_day',
      date: date,
      day_of_week: rule["validations"][:day_of_week]&.first&.day,
      every_nth_day: rule["validations"][:day_of_week]&.first&.occ
    )
  end

  private
  EVERY_NTH_COLLECTION = [['First', 1], ['Second', 2], ['Third', 3], ['Fourth', 4], ['Last', -1]].freeze
  WEEK_DAY_COLLECTION = [['Monday', 0], ['Tuesday', 1], ['Wednesday', 2], ['Thursday', 3], ['Friday', 4], ['Saturday', 5], ['Sunday', 6]].freeze
  DATE_OR_WEEK_DAY_COLLECTION = [['date', 'Date'] ,['week_day', 'Day of the Week']].freeze

end
