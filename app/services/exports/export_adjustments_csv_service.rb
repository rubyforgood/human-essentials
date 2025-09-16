module Exports
  module ExportAdjustmentsCSVService
    class << self
      def generate_csv(adjustments, organization)
        CSV.generate(headers: true) do |csv|
          generate_csv_data(adjustments, organization).each { |row| csv << row }
        end
      end

      def generate_csv_data(adjustments, organization)
        item_names = get_item_names(organization)
        headers = [
          "Created date", "Storage Area",
          "Comment", "Updates"
        ] + item_names

        [headers] + adjustments.map { |adjustment| build_row(adjustment, item_names) }
      end

      private

      def get_item_names(organization)
        organization.items.order(:name).pluck(:name).uniq
      end

      def build_row(adjustment, item_names)
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
end
