module Reports
  class AcquisitionReportService
    include ActionView::Helpers::NumberHelper
    attr_reader :year, :organization

    def initialize(year:, organization:)
      @year = year
      @organization = organization
    end

    def report
      @report ||= { name: 'Diaper Acquisition',
                    entries: {
                      'Disposable diapers distributed' => number_with_delimiter(distributed_diapers),
                      'Average monthly disposable diapers distributed' => number_with_delimiter(monthly_disposable_diapers),
                      'Total diaper drives' => annual_drives.count,
                      'Disposable diapers collected from drives' => number_with_delimiter(disposable_diapers_from_drives),
                      'Money raised from diaper drives' => number_to_currency(money_from_drives),
                      'Total diaper drives (virtual)' => virtual_diaper_drives.count,
                      'Money raised from diaper drives (virtual)' => number_to_currency(money_from_virtual_drives),
                      'Disposable diapers collected from drives (virtual)' => number_with_delimiter(disposable_diapers_from_virtual_drives),
                      '% diapers donated' => "#{percent_donated.round}%",
                      '% diapers bought' => "#{percent_bought.round}%",
                      'Money spent purchasing diapers' => number_to_currency(money_spent_on_diapers),
                      'Purchased from' => purchased_from,
                      'Vendors diapers purchased through' => vendors_purchased_from
                    }
      }
    end

    def distributed_diapers
      @distributed_diapers ||= organization
                               .distributions
                               .for_year(year)
                               .joins(line_items: :item)
                               .merge(Item.disposable)
                               .sum('line_items.quantity')
    end

    def monthly_disposable_diapers
      (distributed_diapers / 12.0).round
    end

    def annual_drives
      organization.diaper_drives.within_date_range("#{year}-01-01 - #{year}-12-31")
    end

    def disposable_diapers_from_drives
      annual_drives.joins(donations: { line_items: :item }).merge(Item.disposable).sum(:quantity)
    end

    def money_from_drives
      annual_drives.joins(:donations).sum(:money_raised) / 100
    end

    def virtual_diaper_drives
      annual_drives.where(virtual: true)
    end

    def money_from_virtual_drives
      virtual_diaper_drives.joins(:donations).sum(:money_raised) / 100
    end

    def disposable_diapers_from_virtual_drives
      virtual_diaper_drives
        .joins(donations: { line_items: :item })
        .merge(Item.disposable)
        .sum(:quantity)
    end

    def percent_donated
      return 0 if incoming_disposable_diapers.zero?

      donated = organization
                  .donations
                  .for_year(year)
                  .joins(line_items: :item)
                  .merge(Item.disposable)
                  .sum(:quantity)

      (donated.to_f / incoming_disposable_diapers) * 100
    end

    def percent_bought
      return 0 if incoming_disposable_diapers.zero?

      purchased = organization
                  .purchases
                  .for_year(year)
                  .joins(line_items: :item)
                  .merge(Item.disposable)
                  .sum(:quantity)

      (purchased.to_f / incoming_disposable_diapers) * 100
    end

    def money_spent_on_diapers
      organization.purchases.for_year(year).sum(:amount_spent_in_cents) / 100.0
    end

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

    def incoming_disposable_diapers
      @incoming_disposable_diapers ||= LineItem.joins(:item)
                                               .merge(Item.disposable)
                                               .where(itemizable: organization.purchases.for_year(year))
                                               .or(LineItem.where(itemizable: organization.donations.for_year(year)))
                                               .sum(:quantity)
    end
  end
end
