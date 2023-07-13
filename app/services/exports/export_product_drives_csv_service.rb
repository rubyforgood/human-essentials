module Exports
  class ExportProductDrivesCSVService
    include ItemsHelper
    HEADERS = ["Product Drive Name", "Start Date", "End Date", "Held Virtually?", "Quantity of Items",
      "Variety of Items", "In Kind Value"].freeze

    def initialize(product_drives, organization, date_range)
      @product_drives = product_drives
      @organization = organization
      @date_range = date_range
    end

    def generate_csv
      CSV.generate do |csv|
        csv << generate_headers

        product_drives.each do |drive|
          csv << generate_row(drive)
        end
      end
    end

    private

    attr_reader :product_drives, :organization, :date_range

    def generate_row(drive)
      [
        drive.name.to_s,
        drive.start_date.strftime("%m-%d-%Y").to_s,
        drive.end_date&.strftime("%m-%d-%Y").to_s,
        (drive.virtual ? "Yes" : "No").to_s,
        drive.donation_quantity_by_date(date_range).to_s,
        drive.distinct_items_count_by_date(date_range).to_s,
        dollar_value(drive.in_kind_value).to_s,
        *drive.item_quantities_by_name_and_date(date_range)
      ]
    end

    def generate_headers
      HEADERS + item_headers
    end

    def item_headers
      return @item_headers if @item_headers

      @item_headers = organization.items.order(:name).pluck(:name)
    end
  end
end
