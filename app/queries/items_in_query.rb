# Creates a query object for retrieving the items, grouped by storage location
# We're using query objects for some of these more complicated queries to get
# the raw SQL out of the models and encapsulate it.
class ItemsInQuery
  attr_reader :organization
  attr_reader :filter_params
  attr_reader :storage_location

  def initialize(organization:, storage_location:, filter_params: nil)
    @organization = organization
    @storage_location = storage_location
    @filter_params = filter_params
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def call
    @items ||=  LineItem.joins("
LEFT OUTER JOIN donations ON donations.id = line_items.itemizable_id AND line_items.itemizable_type = 'Donation'
LEFT OUTER JOIN purchases ON purchases.id = line_items.itemizable_id AND line_items.itemizable_type = 'Purchase'
LEFT OUTER JOIN items ON items.id = line_items.item_id
LEFT OUTER JOIN adjustments ON adjustments.id = line_items.itemizable_id AND line_items.itemizable_type = 'Adjustment'
LEFT OUTER JOIN transfers ON transfers.id = line_items.itemizable_id AND line_items.itemizable_type = 'Transfer'")
                        .where("(donations.storage_location_id = :id or purchases.storage_location_id = :id or (adjustments.storage_location_id = :id and line_items.quantity > 0) or transfers.to_id = :id)  and items.organization_id = :organization_id", id: @storage_location.id, organization_id: @organization.id)
                        .select("sum(line_items.quantity) as quantity, items.id AS item_id, items.name")
                        .group("items.name, items.id")
                        .order("items.name")
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName
end
