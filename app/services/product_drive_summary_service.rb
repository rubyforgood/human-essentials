class ProductDriveSummaryService
  def initialize(product_drives:, within_date_range:, item_category_id:)
    @product_drives = product_drives
    @within_date_range = within_date_range
    @item_category_id = item_category_id
  end

  def call
    calculate_summary
    self
  end

  def fetch_quantity(product_drive_id)
    @summary.dig(product_drive_id, :quantity)
  end

  def fetch_unique_item_count(product_drive_id)
    @summary.dig(product_drive_id, :unique_item_count)
  end

  def fetch_value(product_drive_id)
    @summary.dig(product_drive_id, :value)
  end

  private

  # Returns hash of total quantity, unique item count and value per product drive
  # Example return: { 1 => { quantity: 15, unique_item_count: 2, value: 100 }, ...}
  #
  # @return [Hash<Hash<Symbol, Integer>>]
  def calculate_summary
    @summary ||= begin
      query = ProductDrive
        .left_joins(donations: {line_items: [:item]})
        .where(id: @product_drives.ids)
        .within_date_range(@within_date_range)
        .group("product_drives.id")
        .distinct

      query = query.where(items: {item_category_id: @item_category_id}) if @item_category_id.present?

      query.pluck(Arel.sql(
        "product_drives.id AS id,
        COALESCE(SUM(line_items.quantity), 0) AS quantity,
        COUNT(DISTINCT line_items.item_id) AS unique_item_count,
        COALESCE(SUM(COALESCE(items.value_in_cents, 0) * line_items.quantity), 0) AS value"
      )).to_h do |(id, quantity, unique_item_count, value)|
        [id, {quantity:, unique_item_count:, value:}]
      end
    end
  end
end
