class DispersedPastDatesGenerator
  DAYS_RANGES = [0..6, 7..30, 31..300, 350..700].freeze

  def initialize
    @current_index = 0
  end

  def next
    day = Time.zone.today - rand(DAYS_RANGES[@current_index]).days
    @current_index = if DAYS_RANGES.size - 1 > @current_index
      @current_index.next
    else
      0
    end

    day
  end
end
