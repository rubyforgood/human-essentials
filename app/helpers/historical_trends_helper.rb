module HistoricalTrendsHelper
  MONTHS = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ]

  def last_12_months
    current_month = Time.zone.now.month
    MONTHS.rotate(current_month)
  end
end
