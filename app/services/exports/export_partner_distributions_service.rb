module Exports
  class ExportPartnerDistributionsService
    def initialize(distributions)
      @data = distributions
      @headers = ["Date", "Source Inventory", "Total Items"]
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
          "Date" => distribution.issued_at.strftime("%m/%d/%Y"),
          "Source Inventory" => distribution.storage_location.name,
          "Total Items" => distribution.line_items.total
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
