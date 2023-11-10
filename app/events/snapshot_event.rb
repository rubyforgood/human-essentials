class SnapshotEvent < Event
  serialize :data, EventTypes::StructCoder.new(EventTypes::Inventory)

  # @param organization [Organization]
  # @return [Hash<Integer, EventTypes::EventStorageLocation>]
  def self.storage_locations(organization)
    organization.storage_locations.to_h do |loc|
      [loc.id,
        EventTypes::EventStorageLocation.new(
          id: loc.id,
          items: loc.inventory_items.to_h do |inv_item|
            [inv_item.item_id, EventTypes::EventLineItem.new(
              quantity: inv_item.quantity,
              item_id: inv_item.item_id,
              item_value_in_cents: inv_item.item.value_in_cents,
              from_storage_location: nil,
              to_storage_location: loc.id
            )]
          end
        )]
    end
  end

  # @param organization [Organization]
  def self.publish(organization)
    create(
      eventable: organization,
      organization_id: organization.id,
      event_time: Time.zone.now,
      data: EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: storage_locations(organization)
      )
    )
  end
end
