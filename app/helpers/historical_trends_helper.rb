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
    current_year = Time.zone.now.year
    return_array = MONTHS.rotate(current_month)
    return_array.each_with_index do |month, index|
      return_array[index] = if index >= (MONTHS.length - current_month)
        "#{month} #{current_year}"
      else
        "#{month} #{current_year - 1}"
      end
    end
    return_array
  end
end
