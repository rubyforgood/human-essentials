module Reports
  class AcquisitionReportService
    def initialize(year:, organization:)
      @year = year
      @organization = organization
    end

    def report
      @report ||= {
        total_annual_incoming_disposable_diapers: total_annual_incoming_disposable_diapers,
        distributed_disposabed_diapers: distributed_diapers,
        monthly_disposable_diapers: monthly_disposable_diapers,
        diaper_drive_count: annual_drives.count,
        disposabled_diapers_from_drives: disposabled_diapers_from_drives,
        money_from_drives: money_from_drives,
        virtual_drive_count: virtual_diaper_drives.count,
        money_from_virtual_drives: money_from_virtual_drives,
        number_of_diapers_from_virtual_drives: number_of_diapers_from_virtual_drives,
        percent_donated: percent_donated,
        percent_bought: percent_bought,
        money_spent_on_diapers: money_spent_on_diapers,
        purchased_from: purchased_from,
        vendors_purchased_from: vendors_purchased_from
      }
    end

    def columns_for_csv
      %i[distributed_disposabed_diapers monthly_disposable_diapers diaper_drive_count disposabled_diapers_from_drives
         money_from_drives virtual_drive_count money_from_virtual_drives number_of_diapers_from_virtual_drives
         percent_donated percent_bought percent_bought money_spent_on_diapers purchased_from vendors_purchased_from]
    end

    attr_reader :year, :organization

    def vendors_purchased_from
      # placeholder
      "Unknown"
    end

    def purchased_diapers
      LineItem.where(item: disposable_diaper_items)
              .where(itemizable: yearly_purchases)
              .sum(:quantity)
    end

    def yearly_purchases
      ::Purchase.where(organization: organization)
                .where("extract(year  from issued_at) = ?", year)
    end

    def purchased_from
      yearly_purchases.select(:purchased_from).distinct.pluck(:purchased_from).compact
    end

    def money_spent_on_diapers
      yearly_purchases.sum(:amount_spent_in_cents) / 100.0
    end

    def percent_bought
      (purchased_diapers.to_f / total_annual_incoming_disposable_diapers) * 100
    end

    def percent_donated
      (disposabled_diapers_from_drives.to_f / total_annual_incoming_disposable_diapers) * 100
    end

    def total_annual_incoming_disposable_diapers
      LineItem.where(item: disposable_diaper_items)
              .where(itemizable: Purchase.where(organization: organization)).or(
                LineItem.where(itemizable: Donation.where(organization: organization))
              ).sum(:quantity)
    end

    def disposabled_diapers_from_drives
      LineItem.where(item: disposable_diaper_items)
              .where(itemizable: yearly_drive_donations)
              .sum(:quantity)
    end

    def yearly_drive_donations
      ::Donation.where(organization: organization)
                .where(source: "Diaper Drive")
                .where("extract(year  from issued_at) = ?", year)
    end

    def diaper_drives
      ::DiaperDrive.where(organization: organization)
    end

    def annual_drives
      diaper_drives.within_date_range("#{year}-01-01 - #{year}-12-31")
    end

    def number_of_diapers_from_drives
      annual_drives.map(&:donation_quantity).sum
    end

    def money_from_drives
      annual_drives.map(&:total_money_raised).sum / 100
    end

    def virtual_diaper_drives
      annual_drives.where(virtual: true)
    end

    def money_from_virtual_drives
      virtual_diaper_drives.map(&:total_money_raised).sum / 100
    end

    def number_of_diapers_from_virtual_drives
      virtual_diaper_drives.map(&:donation_quantity).sum
    end

    def yearly_distributions
      ::Distribution.where(organization: organization)
                    .where("extract(year  from issued_at) = ?", year)
    end

    def distributed_diapers
      LineItem.where(item: disposable_diaper_items)
              .where(itemizable: yearly_distributions)
              .sum(:quantity)
    end

    def disposable_diaper_items
      Item.disposable
    end

    def monthly_disposable_diapers
      (distributed_diapers / 12.0).round
    end
  end
end
