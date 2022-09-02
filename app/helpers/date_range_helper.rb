# Encapsulates methods used on the Dashboard that need some business logic
module DateRangeHelper
  def date_range_params
    params.dig(:filters, :date_range).presence || this_year
  end

  def date_range_label
    case (params.dig(:filters, :date_range_label).presence || "this year").downcase
    when "today"
      "today"
    when "yesterday"
      "yesterday"
    when "last 7 days"
      "over the last week"
    when "last 30 days"
      "over the last 30 days"
    when "this month"
      "this month"
    when "last month"
      "last month"
    else
      selected_range_described
    end
  end

  def this_year
    "January 1, #{Time.zone.today.year} - December 31, #{Time.zone.today.year}"
  end

  def selected_interval
    date_range_params.split(" - ").map do |d|
      Date.strptime(d, "%B %d, %Y")
    rescue
      raise "Invalid date: #{d} in #{date_range_params}"
    end
  end

  def selected_range
    start_date, end_date = selected_interval
    (start_date.beginning_of_day)..(end_date.end_of_day)
  end

  def selected_range_described
    start_date, end_date = selected_interval
    if start_date == Time.zone.today
      ""
    elsif end_date == Time.zone.today
      "since #{start_date}"
    else
      "during the period #{start_date.to_fs(:short)} to #{end_date.to_fs(:short)}"
    end
  end
end
