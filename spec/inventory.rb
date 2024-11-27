module TestInventory
  class << self
    # @param storage_location [StorageLocation]
    def clear_inventory(storage_location)
      SnapshotEvent.create!(
        eventable: storage_location.organization,
        organization_id: storage_location.organization_id,
        event_time: Time.zone.now,
        data: EventTypes::Inventory.new(
          organization_id: storage_location.organization.id,
          storage_locations: {
            storage_location.id => EventTypes::EventStorageLocation.new(
              id: storage_location.id,
              items: {}
            )
          }
        )
      )
      storage_location.inventory_items.delete_all
    end

    # Pass in a hash of storage location ID -> { item ID -> quantity}. Blows away any current
    # inventory for the storage locations.
    # @param organization [Organization]
    # @param hash [Integer, Hash<Integer, Integer>]
    def create_inventory(organization, hash)
      hash.each do |sl, items|
        line_items = items.map { |id, quantity| LineItem.new(item_id: id, quantity: quantity) }
        AuditEvent.create!(
          eventable: organization,
          group_id: SecureRandom.hex,
          organization_id: organization.id,
          event_time: Time.zone.now,
          data: EventTypes::AuditPayload.new(
            storage_location_id: sl,
            items: EventTypes::EventLineItem.from_line_items(line_items, to: sl)
          )
        )
      end
      create_inventory_items_from_events(organization.id)
    end

    # @param organization_id [Integer]
    def create_inventory_items_from_events(organization_id)
      inventory = View::Inventory.new(organization_id)
      InventoryItem.joins(:storage_location)
        .where(storage_locations: {organization_id: organization_id})
        .delete_all
      inventory.all_items.each do |item|
        InventoryItem.create!(
          item_id: item.item_id,
          storage_location_id: item.storage_location_id,
          quantity: item.quantity
        )
      end
    end
  end
end
