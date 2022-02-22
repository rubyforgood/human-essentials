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
      "over the 30 days"
    when "this month"
      "this month, so far"
    when "last month"
      "during the last month"
    else
      selected_range_described
    end
  end

  def this_year
    "01/01/#{Time.zone.today.year} - 12/31/#{Time.zone.today.year}"
  end

  def selected_interval
    date_range_params.split(" - ").map { |d| Date.strptime(d, "%m/%d/%Y") }
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
      "during the period #{start_date.to_s(:short)} to #{end_date.to_s(:short)}"
    end
  end
end
