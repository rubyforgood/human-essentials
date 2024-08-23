# Creates a query object for retrieving the items, grouped by storage location, also including quantities
# We're using query objects for some of these more complicated queries to get
# the raw SQL out of the models and encapsulate it.
class ItemsByStorageCollectionAndQuantityQuery
  def self.call(organization:, filter_params:, inventory:)
    items = organization.items.active.order(name: :asc).class_filter(filter_params)
    items.to_h do |item|
      locations = inventory.storage_locations_for_item(item.id).map do |sl|
        {
          id: sl,
          name: inventory.storage_location_name(sl),
          quantity: inventory.quantity_for(storage_location: sl, item_id: item.id)
        }
      end
      [
        item.id,
        {
          item_id: item.id,
          item_name: item.name,
          item_on_hand_minimum_quantity: item.on_hand_minimum_quantity,
          item_on_hand_recommended_quantity: item.on_hand_recommended_quantity,
          item_value: item.value_in_cents,
          item_barcode_count: item.barcode_count,
          locations: locations,
          quantity: inventory.quantity_for(item_id: item.id)
        }
      ]
    end
  end
end
