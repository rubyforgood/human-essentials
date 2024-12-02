class DistributionTotalsService
  def initialize(distributions)
    @distribution_totals = calculate_totals(distributions)
  end

  def total_quantity(filter_ids = [])
    totals = filter_ids.present? ? distribution_totals.slice(*filter_ids) : distribution_totals
    totals.sum { |_, totals| totals[:quantity] }
  end

  def total_value(filter_ids = [])
    totals = filter_ids.present? ? distribution_totals.slice(*filter_ids) : distribution_totals
    totals.sum { |_, totals| totals[:value] }
  end

  def fetch_value(id)
    distribution_totals.dig(id, :value)
  end

  def fetch_quantity(id)
    distribution_totals.dig(id, :quantity)
  end

  private

  attr_reader :distribution_totals

  # Returns hash of total quantity and value of items per distribution
  # Ex: {7=>{quantity: 13309, value: 43000}, 22=>{quantity: 0, value: 0}, ...)
  #
  # @return [Hash<Integer, Hash<Symbol, Integer>>]
  def calculate_totals(distributions)
    distributions
      .left_joins(line_items: [:item])
      .group("distributions.id, line_items.id, items.id")
      .pluck(
        Arel.sql(
          "distributions.id,
          sum(line_items.quantity) OVER (PARTITION BY distributions.id) AS quantity,
          sum(COALESCE(items.value_in_cents, 0) * line_items.quantity) OVER (PARTITION BY distributions.id) AS value"
        )
      ).to_h do |(id, quantity, value)|
        [id, {quantity: quantity || 0, value: value || 0}]
      end
  end
end
