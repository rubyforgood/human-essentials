module Exports
  class ExportTransfersCSVService
    def initialize(transfers:, organization:)
      @transfers = transfers
      @organization = organization
    end

    def generate_csv
      csv_data = generate_csv_data

      CSV.generate(headers: true) do |csv|
        csv_data.each { |row| csv << row }
      end
    end

    def generate_csv_data
      csv_data = []

      csv_data << headers
      @transfers.each do |transfer|
        csv_data << build_row_data(transfer)
      end

      csv_data
    end

    private

    def headers
      base_headers
    end

    def base_table
      {
        "From" => ->(transfer) {
          transfer.from.name
        },
        "To" => ->(transfer) {
          transfer.to.name
        },
        "Comment" => ->(transfer) {
          transfer.comment || "none"
        },
        "Total Moved" => ->(transfer) {
          transfer.line_items.total
        }
      }
    end

    def base_headers
      base_table.keys
    end

    def build_row_data(transfer)
      base_table.values.map { |closure| closure.call(transfer) }
    end
  end
end
