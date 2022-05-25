module Reports
  class OtherProductsReportService
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
      @report ||= { name: 'Other Items',
                    entries: {
                      'Other products distributed' => number_with_delimiter(distributed_products),
                      '% other products donated' => "#{percent_donated.round}%",
                      '% other products bought' => "#{percent_bought.round}%",
                      'Money spent on other products' => number_to_currency(money_spent),
                      'List of other products' => product_list
                    } }
    end

    # @return [Integer]
    def distributed_products
      organization
        .distributions
        .for_year(year)
        .joins(line_items: :item)
        .merge(Item.other_categories)
        .sum('line_items.quantity')
    end

    # @return [Float]
    def percent_donated
      return 0.0 if total_products.zero?

      (donated_products / total_products.to_f) * 100
    end

    # @return [Float]
    def percent_bought
      return 0.0 if total_products.zero?

      (purchased_products / total_products.to_f) * 100
    end

    # @return [Float]
    def money_spent
      organization.purchases.for_year(year).sum(:amount_spent_on_other_cents) / 100.0
    end

    # @return [String]
    def product_list
      organization.items.other_categories.map(&:name).sort.uniq.join(', ')
    end

    # @return [Integer]
    def purchased_products
      @purchased_products ||= LineItem.joins(:item)
                                      .merge(Item.other_categories)
                                      .where(itemizable: organization.purchases.for_year(year))
                                      .sum(:quantity)
    end

    # @return [Integer]
    def total_products
      @total_products ||= purchased_products + donated_products
    end

    # @return [Integer]
    def donated_products
      @donated_products ||= LineItem.joins(:item)
                                    .merge(Item.other_categories)
                                    .where(itemizable: organization.donations.for_year(year))
                                    .sum(:quantity)
    end
  end
end
