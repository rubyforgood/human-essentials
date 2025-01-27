# Calculates the quantity, unique item count, and value for product
# drives from donations (filtered by items donated in a given date range
# and within a given item category if provided).
class ProductDriveSummaryService
  class << self
    ProductDriveSummary = Data.define(:quantity, :unique_item_count, :value)
    NULL_PRODUCT_DRIVE_TOTALS = ProductDriveSummary.new(quantity: 0, unique_item_count: 0, value: 0)

    def call(product_drives:, within_date_range:, item_category_id: nil)
      calculate_totals(product_drives, within_date_range, item_category_id)
    end

    private

    # @return [Hash<Integer, ProductDriveSummary>]
    def calculate_totals(product_drives, within_date_range, item_category_id)
      query = ProductDrive
        .left_joins(donations: {line_items: [:item]})
        .where(id: product_drives.ids)
        .where(donations: {issued_at: within_date_range[0]..within_date_range[1]})
        .group("product_drives.id")
        .distinct

      query = query.where(items: {item_category_id: item_category_id}) if item_category_id.present?

      totals = query.pluck(Arel.sql(
        "product_drives.id AS id,
        COALESCE(SUM(line_items.quantity), 0) AS quantity,
        COUNT(DISTINCT line_items.item_id) AS unique_item_count,
        COALESCE(SUM(COALESCE(items.value_in_cents, 0) * line_items.quantity), 0) AS value"
      )).to_h do |(id, quantity, unique_item_count, value)|
        [id, ProductDriveSummary.new(quantity:, unique_item_count:, value:)]
      end

      # If a product drive has no matching donations/items, set totals to
      # default values (zeroes).
      product_drives.ids.to_h { |id| [id, NULL_PRODUCT_DRIVE_TOTALS] }.merge(totals)
    end
  end
end
