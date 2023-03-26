module Exports
  class ExportProductDrivesCSVService
    include ItemsHelper
    HEADERS = ["Product Drive Name", "Start Date", "End Date", "Held Virtually?", "Quantity of Items",
      "Variety of Items", "In Kind Value"].freeze

    def initialize(product_drives, organization)
      @product_drives = product_drives
      @organization = organization
    end

    def generate_csv
      CSV.generate do |csv|
        csv << generate_headers(organization)

        product_drives.each do |drive|
          csv << generate_row(drive)
        end
      end
    end

    private

    attr_reader :product_drives, :organization

    def generate_row(drive)
      [
        drive.name.to_s,
        drive.start_date.strftime("%m-%d-%Y").to_s,
        drive.end_date&.strftime("%m-%d-%Y").to_s,
        (drive.virtual ? "Yes" : "No").to_s,
        drive.donation_quantity.to_s,
        drive.distinct_items_count.to_s,
        dollar_value(drive.in_kind_value).to_s,
        *drive.items_quantity_by_name
      ]
    end

    def generate_headers(organization)
      HEADERS + item_headers
    end

    def item_headers
      organization.items.order(:name).pluck(:name)
    end
  end
end
