module Exports
  class ExportPartnerDistributionsService
    def initialize(distributions, optional_headers = [])
      @data = distributions
      @headers = ["Date of Distribution", "Source Inventory", "Total Items"]|optional_headers
    end

    def call
      [].tap do |csv_data|
        csv_data << headers

        rows.each do |request_row|
          csv_data << headers.map { |header| request_row[header] }
        end
      end
    end

    private

    attr_reader :data, :headers

    def rows
      data.map do |distribution|
        {
          "Partner" => distribution.partner.name,
          "Date of Distribution" => distribution.issued_at.strftime("%m/%d/%Y"),
          "Source Inventory" => distribution.storage_location.name,
          "Total Items" => distribution.line_items.total,
          "Total Value" => distribution.cents_to_dollar(distribution.line_items.total_value),
          "Delivery Method" => distribution.delivery_method,
          "State" => distribution.state,
          "Agency Representative" => distribution.agency_rep
        }.tap do |row|
          distribution.line_items.quantities_by_name.each do |_id, item_ref|
            row[item_ref[:name]] = item_ref[:quantity]
            headers << item_ref[:name] unless headers.include?(item_ref[:name])
          end
        end
      end
    end
  end
end
