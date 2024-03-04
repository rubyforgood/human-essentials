# Creates a query object for retrieving the items, grouped by storage location
# We're using query objects for some of these more complicated queries to get
# the raw SQL out of the models and encapsulate it.
class ItemsByStorageCollectionQuery
  attr_reader :organization
  attr_reader :filter_params

  def initialize(organization:, filter_params:)
    @organization = organization
    @filter_params = filter_params
  end

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def call
    @items ||=  organization
                .items
                .active
                .joins(' LEFT OUTER JOIN "inventory_items" ON "inventory_items"."item_id" = "items"."id"')
                .joins(' LEFT OUTER JOIN "storage_locations" ON "storage_locations"."id" = "inventory_items"."storage_location_id"')
                .select('
                        items.id,
                        items.name,
                        items.barcode_count,
                        items.partner_key,
                        items.value_in_cents,
                        items.on_hand_minimum_quantity,
                        items.on_hand_recommended_quantity,
                        storage_locations.name as storage_name,
                        storage_locations.id as storage_id,
                        sum(inventory_items.quantity) as quantity
                      ')
                .group("storage_locations.name, storage_locations.id, items.id, items.name")
                .order(name: :asc).class_filter(filter_params)
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName
end
