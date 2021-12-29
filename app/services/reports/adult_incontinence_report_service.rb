module Reports
  class AdultIncontinenceReportService
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
      @report ||= { name: 'Adult Incontinence',
                    entries: {
                      'Adult incontinence supplies distributed' => number_with_delimiter(distributed_supplies),
                      'Adult incontinence supplies per adult per month' => monthly_supplies&.round || 0,
                      'Adult incontinence supplies' => types_of_supplies,
                      '% adult incontinence supplies donated' => "#{percent_donated.round}%",
                      '% adult incontinence bought' => "#{percent_bought.round}%",
                      'Money spent purchasing adult incontinence supplies' => number_to_currency(money_spent_on_supplies)
                    } }
    end

    # @return [Integer]
    def distributed_supplies
      @distributed_supplies ||= organization
                                .distributions
                                .for_year(year)
                                .joins(line_items: :item)
                                .merge(Item.adult_incontinence)
                                .sum('line_items.quantity')
    end

    # @return [Integer]
    def monthly_supplies
      # TODO: this is asking "per adult per month" but I'm not sure how that's different
      # from just getting the average quantity of all line items, which doesn't seem like a useful
      # metric - and the "per month" seems redundant since it would be the same per adult
      # per year - we don't keep track of returning adults so every line item is considered
      # a "new adult"
      organization
        .distributions
        .for_year(year)
        .joins(line_items: :item)
        .merge(Item.adult_incontinence)
        .average('line_items.quantity')
    end

    def types_of_supplies
      organization.items.adult_incontinence.map(&:name).uniq.join(', ')
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
      # TODO: This includes ALL supplies - right now we cannot differentiate specifically for
      # adult incontinence
      organization.purchases.for_year(year).sum(:amount_spent_in_cents) / 100.0
    end

    ###### HELPER METHODS ######

    # @return [Integer]
    def purchased_supplies
      @purchased_supplies ||= LineItem.joins(:item)
                                      .merge(Item.adult_incontinence)
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
                                    .merge(Item.adult_incontinence)
                                    .where(itemizable: organization.donations.for_year(year))
                                    .sum(:quantity)
    end
  end
end
