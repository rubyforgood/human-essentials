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
      base_headers + item_headers
    end

    def base_table
      {
        "From" => ->(transfer) {
          transfer.from.name
        },
        "To" => ->(transfer) {
          transfer.to.name
        },
        "Date" => ->(transfer) {
          transfer.created_at.strftime("%F")
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

    def item_headers
      @item_headers ||= @organization.items.select("DISTINCT ON (LOWER(name)) items.name").order("LOWER(name) ASC").map(&:name)
    end

    def headers_with_indexes
      @headers_with_indexes ||= headers.each_with_index.to_h
    end

    def build_row_data(transfer)
      row = base_table.values.map { |closure| closure.call(transfer) }

      row += Array.new(item_headers.size, 0)

      transfer.line_items.each do |line_item|
        item_name = line_item.item.name
        item_column_idx = headers_with_indexes[item_name]
        next unless item_column_idx

        row[item_column_idx] += line_item.quantity
      end

      row
    end
  end
end
