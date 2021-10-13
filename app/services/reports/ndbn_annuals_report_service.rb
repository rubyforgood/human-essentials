module Reports
  class NdbnAnnualsReportService
    def initialize(year:, organization:)
      @year = year
      @organization = organization

      # Diaper Aquisition report values
      @number_of_diapers_from_drives = number_of_diapers_from_drives
      @money_from_drives = money_from_drives
      @virtual_diaper_drives = virtual_diaper_drives
      @money_from_virtual_drives = money_from_virtual_drives
      @number_of_diapers_from_virtual_drives = number_of_diapers_from_virtual_drives
    end

    def report
      {
        diaper_drives: diaper_drives,
        number_of_diapers_from_drives: number_of_diapers_from_drives,
        money_from_drives: money_from_drives,
        virtual_diaper_drives: virtual_diaper_drives,
        money_from_virtual_drives: money_from_virtual_drives,
        number_of_diapers_from_virtual_drives: number_of_diapers_from_virtual_drives,
        donated_diapers: donated_diapers
      }
    end

    private

    attr_reader :year, :organization

    def donated_diapers
      LineItem.where(item: diaper_items)
              .where(itemizable: yearly_donations)
              .sum(:quantity)
    end

    def diaper_items
      Item.where(base_item: ::BaseItem.where("lower(category) LIKE '%diaper%'"))
    end

    def yearly_donations
      ::Donation.where(organization: organization)
                .where("extract(year  from issued_at) = ?", year)
                .includes(line_items: :item)
    end

    def diaper_drives
      ::DiaperDrive.where(organization: organization)
    end

    def annual_drives
      diaper_drives.within_date_range("2021-01-01 - 2021-12-31")
    end

    def number_of_diapers_from_drives
      annual_drives.map(&:donation_quantity).sum
    end

    def money_from_drives
      annual_drives.map(&:in_kind_value).sum
    end

    def virtual_diaper_drives
      annual_drives.where(virtual: true)
    end

    def money_from_virtual_drives
      virtual_diaper_drives.map(&:donation_quantity).sum
    end

    def number_of_diapers_from_virtual_drives
      virtual_diaper_drives.map(&:in_kind_value).sum
    end
  end
end