module Reports
  class AcquisitionReportService
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
      @report ||= { name: 'Diaper Acquisition',
                    entries: {
                      'Disposable diapers distributed' => number_with_delimiter(distributed_diapers),
                      'Average monthly disposable diapers distributed' => number_with_delimiter(monthly_disposable_diapers),
                      'Total product drives' => annual_drives.count,
                      'Disposable diapers collected from drives' => number_with_delimiter(disposable_diapers_from_drives),
                      'Money raised from product drives' => number_to_currency(money_from_drives),
                      'Total product drives (virtual)' => virtual_product_drives.count,
                      'Money raised from product drives (virtual)' => number_to_currency(money_from_virtual_drives),
                      'Disposable diapers collected from drives (virtual)' => number_with_delimiter(disposable_diapers_from_virtual_drives),
                      '% diapers donated' => "#{percent_donated.round}%",
                      '% diapers bought' => "#{percent_bought.round}%",
                      'Money spent purchasing diapers' => number_to_currency(money_spent_on_diapers),
                      'Purchased from' => purchased_from,
                      'Vendors diapers purchased through' => vendors_purchased_from
                    } }
    end

    # @return [Integer]
    def distributed_diapers
      @distributed_diapers ||= organization
                               .distributions
                               .for_year(year)
                               .joins(line_items: :item)
                               .merge(Item.disposable)
                               .sum('line_items.quantity')
    end

    # @return [Integer]
    def monthly_disposable_diapers
      (distributed_diapers / 12.0).round
    end

    # @return [ActiveRecord::Relation]
    def annual_drives
      organization.product_drives.within_date_range("#{year}-01-01 - #{year}-12-31").where(virtual: false)
    end

    # @return [Integer]
    def disposable_diapers_from_drives
      @disposable_diapers_from_drives ||=
        annual_drives.joins(donations: { line_items: :item }).merge(Item.disposable).sum(:quantity)
    end

    # @return [Float]
    def money_from_drives
      annual_drives.joins(:donations).sum(:money_raised) / 100
    end

    # @return [Integer]
    def virtual_product_drives
      organization.product_drives.within_date_range("#{year}-01-01 - #{year}-12-31").where(virtual: true)
    end

    # @return [Float]
    def money_from_virtual_drives
      virtual_product_drives.joins(:donations).sum(:money_raised) / 100
    end

    # @return [Integer]
    def disposable_diapers_from_virtual_drives
      @disposable_diapers_from_virtual_drives ||= virtual_product_drives
                                                  .joins(donations: { line_items: :item })
                                                  .merge(Item.disposable)
                                                  .sum(:quantity)
    end

    # @return [Float]
    def percent_donated
      return 0.0 if total_diapers.zero?

      (donated_diapers / total_diapers.to_f) * 100
    end

    # @return [Float]
    def percent_bought
      return 0.0 if total_diapers.zero?

      (purchased_diapers / total_diapers.to_f) * 100
    end

    # @return [Float]
    def money_spent_on_diapers
      organization.purchases.for_year(year).sum(:amount_spent_on_diapers_cents) / 100.0
    end

    # @return [String]
    def purchased_from
      organization
        .purchases
        .for_year(year)
        .select(:purchased_from)
        .distinct
        .pluck(:purchased_from)
        .compact
        .join(', ')
    end

    # @return [String]
    def vendors_purchased_from
      organization
        .vendors
        .joins(:purchases)
        .merge(Purchase.for_year(year))
        .select(:business_name)
        .distinct
        .pluck(:business_name)
        .compact
        .join(', ')
    end

    ###### HELPER METHODS ######

    # @return [Integer]
    def purchased_diapers
      @purchased_diapers ||= LineItem.joins(:item)
                                     .merge(Item.disposable)
                                     .where(itemizable: organization.purchases.for_year(year))
                                     .sum(:quantity)
    end

    # @return [Integer]
    def total_diapers
      @total_diapers ||= purchased_diapers + donated_diapers
    end

    # @return [Integer]
    def donated_diapers
      @donated_diapers ||= LineItem.joins(:item)
                                   .merge(Item.disposable)
                                   .where(itemizable: organization.donations.for_year(year))
                                   .sum(:quantity)
    end
  end
end
