# Encapsulates methods used on the Dashboard that need some business logic
module DateRangeHelper
  def display_interval
    selected_interval.humanize.downcase
  end

  def selected_interval
    if params.dig(:dates, :date_interval)
      "after " + params.dig(:dates, :date_interval)
    else
      "until today"
    end
  end

  def selected_range
    now = Time.zone.now.end_of_day
    start_date = params.dig(:dates, :date_interval)
    start_date = start_date.present? ? Date.strptime(start_date, '%m/%d/%Y')&.to_date : "Jan, 1, 2017".to_date
    start_date..now
  end
end
