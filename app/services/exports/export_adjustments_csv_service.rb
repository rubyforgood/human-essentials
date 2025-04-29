module Exports
  class ExportAdjustmentsCSVService
    def initialize(adjustments:, organization:)
      @adjustments = adjustments
      @organization = organization
    end

    def generate_csv
      CSV.generate(headers: true) do |csv|
        generate_csv_data.each { |row| csv << row }
      end
    end

    def generate_csv_data
      [headers] + @adjustments.map { |adjustment| build_row(adjustment) }
    end

    private

    def headers
      [
        "Created date", "Storage Area",
        "Comment", "# of changes"
      ] + item_names
    end

    def item_names
      @organization.items.order(:name).pluck(:name).uniq
    end

    def build_row(adjustment)
      row = [
        adjustment.created_at.strftime("%F"),
        adjustment.storage_location.name,
        adjustment.comment,
        adjustment.line_items.count { |item| !item.quantity.eql?(0) }
      ]

      item_quantities = Hash.new(0)

      adjustment.line_items.each do |line_item|
        item_quantities[line_item.item.name] += line_item.quantity
      end

      item_names.each do |item_name|
        row << item_quantities[item_name]
      end

      row
    end
  end
end
