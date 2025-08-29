class DistributionTotalsService
  DistributionTotal = Data.define(:quantity, :value)

  class << self
    # @param distributions [Distribution::ActiveRecord_Relation]
    # @return [Hash<Integer, DistributionTotal>]
    def call(distributions)
      calculate_totals(distributions)
    end

    private

    # Returns hash with quantity/value totals for each distribution.
    # NOTE: Quantity and value of items are reduced if item filtering present (id/category)
    #
    # @return [Hash<Integer, DistributionTotal>]
    def calculate_totals(distributions)
      distributions
        .left_joins(line_items: [:item])
        .group("distributions.id, line_items.id, items.id")
        .pluck(
          Arel.sql(
            "distributions.id,
            COALESCE(SUM(line_items.quantity) OVER (PARTITION BY distributions.id), 0) AS quantity,
            COALESCE(SUM(COALESCE(items.value_in_cents, 0) * line_items.quantity) OVER (PARTITION BY distributions.id), 0) AS value"
          )
        )
        .to_h do |(id, quantity, value)|
          [id, DistributionTotal.new(quantity:, value:)]
        end
    end
  end
end
