module Reports
  class PeriodSupplyReportService
    include ActionView::Helpers::NumberHelper
    attr_reader :year, :organization

    # @param year [Integer]
    # @param organization [Organization]
    def initialize(year:, organization:)
      @year = year
      @organization = organization
    end

    # @return [Hash]
    def report
      @report ||= {name: "Period Supplies",
                   entries: {
                     "Period supplies distributed" => number_with_delimiter(distributed_supplies),
                     "Period supplies per adult per month" => monthly_supplies&.round || 0,
                     "Period supplies" => types_of_supplies,
                     "% period supplies donated" => "#{percent_donated.round}%",
                     "% period supplies bought" => "#{percent_bought.round}%",
                     "Money spent purchasing period supplies" => number_to_currency(money_spent_on_supplies)
                   }}
    end

    # @return [Integer]
    def distributed_supplies
      @distributed_supplies ||= organization
        .distributions
        .for_year(year)
        .joins(line_items: :item)
        .merge(Item.period_supplies)
        .sum("line_items.quantity")
    end

    # @return [Integer]
    def monthly_supplies
      # NOTE: This is asking "per adult per month" but there doesn't seem to be much difference
      # in calculating per month or per any other time frame, since all it's really asking
      # is the value of the `distribution_quantity` field for the items we're giving out.
      organization
        .distributions
        .for_year(year)
        .joins(line_items: :item)
        .merge(Item.period_supplies)
        .average("COALESCE(items.distribution_quantity, 50)")
    end

    def types_of_supplies
      organization.items.period_supplies.map(&:name).uniq.sort.join(", ")
    end

    # @return [Float]
    def percent_donated
      return 0.0 if total_supplies.zero?

      (donated_supplies / total_supplies.to_f) * 100
    end

    # @return [Float]
    def percent_bought
      return 0.0 if total_supplies.zero?

      (purchased_supplies / total_supplies.to_f) * 100
    end

    # @return [String]
    def money_spent_on_supplies
      organization.purchases.for_year(year).sum(:amount_spent_on_period_supplies_cents) / 100.0
    end

    ###### HELPER METHODS ######

    # @return [Integer]
    def purchased_supplies
      @purchased_supplies ||= LineItem.joins(:item)
        .merge(Item.period_supplies)
        .where(itemizable: organization.purchases.for_year(year))
        .sum(:quantity)
    end

    # @return [Integer]
    def total_supplies
      @total_supplies ||= purchased_supplies + donated_supplies
    end

    # @return [Integer]
    def donated_supplies
      @donated_supplies ||= LineItem.joins(:item)
        .merge(Item.period_supplies)
        .where(itemizable: organization.donations.for_year(year))
        .sum(:quantity)
    end
  end
end
