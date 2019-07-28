# Encapsulates methods used on the Dashboard that need some business logic
module DateRangeHelper
  def display_interval
    selected_interval.humanize.downcase
  end

  def filter_intervals
    [
      %w(Today today),
      %w(Yesterday yesterday),
      ["This Week", "this_week"],
      ["This Month", "this_month"],
      ["Last Month", "last_month"],
      ["This Year", "this_year"],
      ["Last Year", "last_year"],
    ]
  end

  def selected_interval
    params.dig(:filters, :interval) || "this_year"
  end

  def selected_range(selected_interval)
    now = Time.zone.now
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
      now.beginning_of_year..now.end_of_year
    when "last_year"
      (now - 1.year).beginning_of_year..(now - 1.year).end_of_year
    else
      Time.zone.local(2017, 1, 1, 0, 0, 0)..Time.zone(2030,1,1,0,0,0)
    end
  end
end
