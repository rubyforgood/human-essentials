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

  # "Sep 2025" -- the long form, for the chart's axis and for the sentence a screen reader hears
  # about each sparkline, where there is room and where the year matters.
  def last_12_months
    current_month = Time.zone.now.month
    current_year = Time.zone.now.year
    last_year = current_year - 1
    return_array = MONTHS.rotate(current_month)
    return_array.each_with_index do |month, index|
      # Last current_month entries are in the current year, earlier entries are
      # in the previous year.
      return_array[index] = if index >= (MONTHS.length - current_month)
        "#{month} #{current_year}"
      else
        "#{month} #{last_year}"
      end
    end
    return_array
  end

  # "Sep 25" -- the short form, for a column header.
  #
  # The long form set the width of all twelve columns: an eight-character heading over a
  # five-character figure, 88px a column, **1,054px of a 1,423px table**. A twelve-month table is
  # wide by construction and the heading should not be the reason. Two digits of year still say
  # which September this is, which is the only thing the year is doing here.
  def last_12_months_short
    last_12_months.map { |label| label.sub(/ (\d{2})(\d{2})\z/, ' \2') }
  end
end
