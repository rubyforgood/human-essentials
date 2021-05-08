module Exports
  class ExportDistributionsCSVService
    def initialize(distributions)
      @distributions = distributions
    end

    def generate_csv
      csv_data = []

      csv_data << headers

      distributions.each do |distribution|
        csv_data << build_row_data(distribution)
      end

      csv_data
    end

    private

    attr_reader :distributions

    def headers
      base_headers + item_headers
    end

    def base_headers
      [
        "Partner",
        "Date of Distribution",
        "Source Inventory",
        "Total Items",
        "Total Value",
        "Delivery Method",
        "State",
        "Agency Representative"
      ]
    end

    def item_headers
      item_names = distributions.map(&:line_items).flatten.map(&:item).map do |item|
        item.name
      end

      item_names.sort.uniq
    end

    def build_row_data(distribution)
      row = [
        distribution.partner.name,
        distribution.issued_at.strftime("%m/%d/%Y"),
        distribution.storage_location.name,
        distribution.line_items.total,
        distribution.cents_to_dollar(distribution.line_items.total_value),
        distribution.delivery_method,
        distribution.state,
        distribution.agency_rep
      ]

      row = row + Array.new(item_headers.size, 0)

      distribution.line_items.includes(:item).each do |line_item|
        item_name = line_item.item.name
        item_column_idx = headers.index(item_name)
        row[item_column_idx] = line_item.quantity
      end

      row
    end

  end
end
