# Encapsulates methods used on the Dashboard that need some business logic
module DateRangeHelper
  def display_interval
    selected_interval.humanize.downcase
  end

  def filter_intervals
    [
      %w(Today today),
      %w(Yesterday yesterday),
      ["This Week to date", "this_week"],
      ["This Month to date", "this_month"],
      ["Last Month", "last_month"],
      ["This Year to date", "this_year"],
      ["Last Year", "last_year"],
      ["All Time", "all_time"],
    ]
  end

  def selected_interval
    params.dig(:filters, :interval) || "this_year"
  end

  def selected_range
    now = Time.zone.now.end_of_day
    case selected_interval
    when "today"
      now.beginning_of_day..now
    when "yesterday"
      (now - 1.day).beginning_of_day..(now - 1.day).end_of_day
    when "this_week"
      now.beginning_of_week..now
    when "this_month"
      now.beginning_of_month..now
    when "last_month"
      (now - 1.month).beginning_of_month..(now - 1.month).end_of_month
    when "this_year"
      now.beginning_of_year..now
    when "last_year"
      (now - 1.year).beginning_of_year..(now - 1.year).end_of_year
    else
      Time.zone.local(2017, 1, 1, 0, 0, 0)..now
    end
  end
end
