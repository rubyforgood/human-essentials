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
                      'Disposable diapers distributed' => number_with_delimiter(total_diapers_distributed),
                      'Cloth diapers distributed' => number_with_delimiter(distributed_cloth_diapers),
                      'Average monthly disposable diapers distributed' => number_with_delimiter(monthly_disposable_diapers),
                      'Total product drives' => annual_drives.count,
                      'Disposable diapers collected from drives' => number_with_delimiter(disposable_diapers_from_drives),
                      'Cloth diapers collected from drives' => number_with_delimiter(cloth_diapers_from_drives),
                      'Money raised from product drives' => number_to_currency(money_from_drives),
                      'Total product drives (virtual)' => virtual_product_drives.count,
                      'Money raised from product drives (virtual)' => number_to_currency(money_from_virtual_drives),
                      'Disposable diapers collected from drives (virtual)' => number_with_delimiter(disposable_diapers_from_virtual_drives),
                      'Cloth diapers collected from drives (virtual)' => number_with_delimiter(cloth_diapers_from_virtual_drives),
                      '% disposable diapers donated' => "#{percent_disposable_donated.round}%",
                      '% cloth diapers donated' => "#{percent_cloth_diapers_donated.round}%",
                      '% disposable diapers purchased' => "#{percent_disposable_diapers_purchased.round}%",
                      '% cloth diapers purchased' => "#{percent_cloth_diapers_purchased.round}%",
                      'Money spent purchasing diapers' => number_to_currency(money_spent_on_diapers),
                      'Purchased from' => purchased_from,
                      'Vendors diapers purchased through' => vendors_purchased_from
                    } }
    end

    # @return [Integer]
    def distributed_disposable_diapers
      @distributed_disposable_diapers ||= organization
                               .distributions
                               .for_year(year)
                               .joins(line_items: :item)
                               .merge(Item.disposable)
                               .sum('line_items.quantity')
    end

    def distributed_diapers_from_kits
      @distributed_diapers_from_kits ||= organization
        .kits
        .joins(inventory_items: :item)
        .merge(Item.disposable)
        .where("kits.id IN (SELECT DISTINCT kits.id FROM line_items
                         JOIN distributions ON distributions.id = line_items.itemizable_id
                         WHERE line_items.itemizable_type = 'Distribution'
                           AND EXTRACT(YEAR FROM distributions.issued_at) = ?)", year)
        .sum('inventory_items.quantity')
    end

    def total_diapers_distributed
      distributed_diapers + distributed_diapers_from_kits
    end

    def distributed_cloth_diapers
      @distributed_cloth_diapers ||= organization
                               .distributions
                               .for_year(year)
                               .joins(line_items: :item)
                               .merge(Item.cloth_diapers)
                               .sum('line_items.quantity')
    end

    def distributed_cloth_diapers
      @distributed_cloth_diapers ||= organization
                               .distributions
                               .for_year(year)
                               .joins(line_items: :item)
                               .merge(Item.cloth_diapers)
                               .sum('line_items.quantity')
    end

    # @return [Integer]
    def monthly_disposable_diapers
      (distributed_disposable_diapers / 12.0).round
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

    def cloth_diapers_from_drives
      @cloth_diapers_from_drives ||=
        annual_drives.joins(donations: { line_items: :item }).merge(Item.cloth_diapers).sum(:quantity)
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

    # @return [Integer]
    def cloth_diapers_from_virtual_drives
      @cloth_diapers_from_virtual_drives ||= virtual_product_drives
                                                  .joins(donations: { line_items: :item })
                                                  .merge(Item.cloth_diapers)
                                                  .sum(:quantity)
    end

    # @return [Float]
    def percent_disposable_donated
      return 0.0 if total_disposable_diapers.zero?

      (donated_disposable_diapers / total_disposable_diapers.to_f) * 100
    end

    # @return [Float]
    def percent_cloth_diapers_donated
      return 0.0 if total_cloth_diapers.zero?

      (donated_cloth_diapers / total_cloth_diapers.to_f) * 100
    end

    # @return [Float]
    def percent_cloth_diapers_purchased
      return 0.0 if purchased_cloth_diapers.zero?

      (purchased_cloth_diapers / total_cloth_diapers.to_f) * 100
    end

    # @return [Float]
    def percent_disposable_diapers_purchased
      return 0.0 if purchased_disposable_diapers.zero?

      (purchased_disposable_diapers / total_disposable_diapers.to_f) * 100
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
    def purchased_disposable_diapers
      @purchased_diapers ||= LineItem.joins(:item)
                                     .merge(Item.disposable)
                                     .where(itemizable: organization.purchases.for_year(year))
                                     .sum(:quantity)
    end

    # @return [Integer]
    def purchased_cloth_diapers
      @purchased_cloth_diapers ||= LineItem.joins(:item)
                                           .merge(Item.cloth_diapers)
                                           .where(itemizable: organization.purchases.for_year(year))
                                           .sum(:quantity)
    end

    # @return [Integer]
    def total_disposable_diapers
      @total_disposable_diapers ||= purchased_disposable_diapers + donated_disposable_diapers
    end

    # @return [Integer]
    def total_cloth_diapers
      @total_cloth_diapers ||= purchased_cloth_diapers + donated_cloth_diapers
    end

    # @return [Integer]
    def donated_disposable_diapers
      @donated_diapers ||= LineItem.joins(:item)
                                   .merge(Item.disposable)
                                   .where(itemizable: organization.donations.for_year(year))
                                   .sum(:quantity)
    end

    # @return [Integer]
    def donated_cloth_diapers
      @donated_cloth_diapers ||= LineItem.joins(:item)
                                          .merge(Item.cloth_diapers)
                                          .where(itemizable: organization.donations.for_year(year))
                                          .sum(:quantity)
    end
  end
end
