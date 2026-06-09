module Exports
  class ExportProductDriveParticipantsCSVService
    include ItemsHelper

    HEADERS = ["Donation Id", "Product Drive Participant", "Storage Location", "Quantity", "In Kind Value"].freeze

    def initialize(product_drive)
      @product_drive = product_drive
    end

    def generate_csv
      CSV.generate do |csv|
        csv << generate_headers

        product_drive.donations.includes(:product_drive_participant).find_each do |donation|
          csv << generate_row(donation)
        end
      end
    end

    private

    attr_reader :product_drive

    def generate_row(donation)
      [
        donation.id.to_s,
        donation.product_drive_participant_id ? donation.product_drive_participant.business_name : nil,
        donation.storage_location.name,
        donation.line_items.count(&:quantity),
        dollar_value(donation.value_per_itemizable)
      ]
    end

    def generate_headers
      HEADERS
    end
  end
end
