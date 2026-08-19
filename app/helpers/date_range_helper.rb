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

  # The ranges the date filter offers, as name => [start, end].
  #
  # Computed here rather than in the browser. Litepicker built these with luxon's
  # DateTime.now(), which is the *browser's* midnight, while the query they feed is filtered
  # with Time.zone -- so "Today" could be a day out for anyone whose clock disagreed with the
  # organization's zone.
  #
  # Ordered shortest window to longest, with the catch-alls last, which is the order Stripe,
  # Google Analytics and Metabase all use. "Default" leads because it is the range the page
  # arrives on, and it is named for what it shows: this app schedules distributions ahead, so
  # the default window deliberately runs into the future.
  #
  # The keys land in filters[date_range_label] verbatim, and #date_range_label matches them
  # after downcasing -- which is why sentence case here is safe.
  def date_range_presets
    today = Time.zone.today
    last_month = today - 1.month

    {
      "Default (recent and upcoming)" => [2.months.ago.to_date, 1.month.from_now.to_date],
      "Today" => [today, today],
      "Yesterday" => [today - 1.day, today - 1.day],
      "Last 7 days" => [today - 6.days, today],
      "Last 30 days" => [today - 29.days, today],
      "This month" => [today.beginning_of_month, today.end_of_month],
      "Last month" => [last_month.beginning_of_month, last_month.end_of_month],
      "Last 12 months" => [today - 12.months + 1.day, today],
      "This year" => [today.beginning_of_year, today.end_of_year],
      "Prior year" => [(today - 1.year).beginning_of_year, (today - 1.year).end_of_year],
      "All time" => [today - 100.years, today + 1.year]
    }
  end

  # Which preset the current selection corresponds to, or nil when the dates match none of
  # them and the filter should read as custom.
  #
  # Matched on the dates rather than on filters[date_range_label], because that parameter
  # cannot be trusted to describe the range: before this control existed nothing kept the two
  # in step, and a stale label would have selected the wrong option.
  def selected_date_range_preset
    interval = selected_interval
    date_range_presets.find { |_name, range| range == interval }&.first
  end

  def selected_interval
    date_range_params.split(" - ").map do |d|
      Date.strptime(d, "%B %d, %Y")
    rescue
      flash.now[:notice] = "Invalid Date range provided. Reset to default date range"
      return default_date.split(" - ").map do |d|
        Date.strptime(d.to_s, "%B %d, %Y")
      end
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
