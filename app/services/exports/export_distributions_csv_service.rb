module Exports
  class ExportDistributionsCSVService
    def initialize(distribution_ids:)
      # Use a where lookup so that I can eager load all the resources needed
      # rather than depending on external code to do it for me. This makes
      # this code more self contained and efficient!
      @distributions = Distribution.includes(:partner, :storage_location, line_items: [:item]).where(id: distribution_ids).order('issued_at DESC')
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
      distributions.each do |distribution|
        csv_data << build_row_data(distribution)
      end

      csv_data
    end

    private

    attr_reader :distributions

    def headers
      # Build the headers in the correct order
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
      # Define the item_headers by taking each item name
      # and sort them alphabetically
      item_names = distributions.map do |distribution|
        distribution.line_items.map(&:item).map(&:name)
      end.flatten

      item_names.sort.uniq
    end

    def build_row_data(distribution)
      # Maybe utilize hash instead of array. (scott add comments that make senses)
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

      row += Array.new(item_headers.size, 0)

      distribution.line_items.each do |line_item|
        item_name = line_item.item.name
        item_column_idx = headers.index(item_name)
        row[item_column_idx] = line_item.quantity
      end

      row
    end
  end
end
