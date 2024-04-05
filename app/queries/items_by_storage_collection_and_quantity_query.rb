# Creates a query object for retrieving the items, grouped by storage location, also including quantities
# We're using query objects for some of these more complicated queries to get
# the raw SQL out of the models and encapsulate it.
class ItemsByStorageCollectionAndQuantityQuery
  def self.call(organization:, filter_params:, inventory: nil)
    if inventory
      items = organization.items.active.order(name: :asc).class_filter(filter_params)
      return items.to_h do |item|
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

    items_by_storage_collection = ItemsByStorageCollectionQuery.new(organization: organization, filter_params: filter_params).call
    items_by_storage_collection_and_quantity = Hash.new
    items_by_storage_collection.each do |row|
      unless items_by_storage_collection_and_quantity.key?(row.id)
        items_by_storage_collection_and_quantity[row.id] = {
          item_id: row.id,
          item_name: row.name,
          item_on_hand_minimum_quantity: row.on_hand_minimum_quantity,
          item_on_hand_recommended_quantity: row.on_hand_recommended_quantity,
          item_value: row.value_in_cents,
          item_barcode_count: row.barcode_count,
          locations: [],
          quantity: 0
        }
      end

      if row.storage_id
        items_by_storage_collection_and_quantity[row.id][:locations] << {
          id: row.storage_id,
          name: row.storage_name,
          quantity: row.quantity
        }
      end
      items_by_storage_collection_and_quantity[row.id][:quantity] += row.quantity || 0
    end

    items_by_storage_collection_and_quantity
  end
end
