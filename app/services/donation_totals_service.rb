class DonationTotalsService
  DonationTotal = Data.define(:quantity, :value)

  class << self
    # @param donations [Donation::ActiveRecord_Relation]
    # @return [Hash<Integer, DonationTotal>]
    def call(donations)
      calculate_totals(donations)
    end

    private

    # Returns a hash with quantity/value totals for each donation.
    #
    # @return [Hash<Integer, DonationTotal>]
    def calculate_totals(donations)
      donations
        .left_joins(line_items: [:item])
        .group("donations.id, line_items.id, items.id")
        .pluck(
          Arel.sql(
            "donations.id,
            COALESCE(SUM(line_items.quantity) OVER (PARTITION BY donations.id), 0) AS quantity,
            COALESCE(SUM(COALESCE(items.value_in_cents, 0) * line_items.quantity) OVER (PARTITION BY donations.id), 0) AS value"
          )
        )
        .to_h do |(id, quantity, value)|
          [id, DonationTotal.new(quantity:, value:)]
        end
    end
  end
end
