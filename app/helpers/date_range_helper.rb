# Encapsulates methods used on the Dashboard that need some business logic
module DateRangeHelper
  def date_range_params
    params.dig(:filters, :date_range).presence || default_date
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
    when "last 12 months"
      "last 12 months"
    when "prior year"
      "prior year"
    else
      selected_range_described
    end
  end

  def default_date
    start_date = 2.months.ago.to_date
    end_date = 1.month.from_now.to_date
    "#{start_date.strftime("%B %d, %Y")} - #{end_date.strftime("%B %d, %Y")}"
  end

  def parse_date_range(date_range_string)
    parts = date_range_string.to_s.split(" - ")
    return nil unless parts.size == 2

    parts.map { |d| Date.strptime(d.strip, "%B %d, %Y") }
  rescue ArgumentError => e
    Rails.logger.warn("Invalid date range '#{date_range_string}': #{e.message}")
    nil
  end

  def selected_interval
    parse_date_range(date_range_params) || parse_date_range(default_date)
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

  def date_range_params_invalid?
    parse_date_range(date_range_params).nil?
  end
end
