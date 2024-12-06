class DistributionTotalsService
  def initialize(distributions, filter_params)
    @filter_params = filter_params
    @distribution_quantities = calculate_quantities(distributions)
    @distribution_values = calculate_values(distributions)
  end

  def total_quantity(filter_ids = [])
    totals = filter_ids.present? ? @distribution_quantities.slice(*filter_ids) : @distribution_quantities
    totals.sum { |_, quantity| quantity }
  end

  def total_value(filter_ids = [])
    totals = filter_ids.present? ? @distribution_values.slice(*filter_ids) : @distribution_values
    totals.sum { |_, value| value }
  end

  def fetch_value(id)
    @distribution_values.fetch(id)
  end

  def fetch_quantity(id)
    @distribution_quantities.fetch(id)
  end

  private

  attr_reader :filter_params

  # Returns hash of total quantity of items per distribution
  # Quantity of items after item filtering (id/category)
  #
  # @return [Hash<Integer, Integer>]
  def calculate_quantities(distributions)
    distributions
      .class_filter(filter_params)
      .left_joins(line_items: [:item])
      .group("distributions.id, line_items.id, items.id")
      .pluck(
        Arel.sql(
          "distributions.id,
          COALESCE(SUM(line_items.quantity) OVER (PARTITION BY distributions.id), 0) AS quantity"
        )
      )
      .to_h
  end

  # Returns hash of total value of items per distribution WIHOUT item id/category filter
  # Value of entire distribution (not reduced by filtered items)
  #
  # @return [Hash<Integer, Integer>]
  def calculate_values(distributions)
    distributions
      .where(id: distributions.class_filter(filter_params))
      .left_joins(line_items: [:item])
      .group("distributions.id, line_items.id, items.id")
      .pluck(
        Arel.sql(
          "distributions.id,
          COALESCE(SUM(COALESCE(items.value_in_cents, 0) * line_items.quantity) OVER (PARTITION BY distributions.id), 0) AS value"
        )
      )
      .to_h
  end
end
