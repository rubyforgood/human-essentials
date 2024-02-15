class DispersedPastDatesGenerator
  RANGES = [0..6, 7..31, 32..300, 350..700].freeze

  def initialize(dates_quantity)
    @dates_quantity = dates_quantity
    @current_iteration = 0.0
    @dates_per_range = (dates_quantity.to_f / RANGES.size).ceil
  end

  def next
    range_index = (current_iteration / dates_per_range).to_i

    if dates_quantity > current_iteration
      @current_iteration += 1
    else
      0.0
    end

    Time.zone.today - rand(RANGES[range_index]).days
  end

  private

  attr_reader :dates_quantity, :dates_per_range, :current_iteration
end
