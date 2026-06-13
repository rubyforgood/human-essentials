module Exports
  class ExportProductDriveParticipantsCSVService
    HEADERS = ["Donation Id", "Product Drive Participant", "Storage Location", "Quantity", "In Kind Value"].freeze

    class << self
      include ItemsHelper

      def generate_csv(product_drive)
        CSV.generate do |csv|
          csv << HEADERS

          product_drive.donations.includes(:product_drive_participant).find_each do |donation|
            csv << generate_row(donation)
          end
        end
      end

      private

      def generate_row(donation)
        [
          donation.id.to_s,
          donation.product_drive_participant_id ? donation.product_drive_participant.business_name : nil,
          donation.storage_location.name,
          donation.line_items.count(&:quantity),
          dollar_value(donation.value_per_itemizable)
        ]
      end
    end
  end
end
