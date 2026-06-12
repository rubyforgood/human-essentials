class KitAllocateEvent < Event
  def self.event_line_items(kit_item, storage_location, quantity)
    items = kit_item.line_items.map do |item|
      EventTypes::EventLineItem.new(
        quantity: item.quantity * quantity,
        item_id: item.item_id,
        item_value_in_cents: item.item.value_in_cents,
        from_storage_location: storage_location,
        to_storage_location: nil
      )
    end
    items.push(EventTypes::EventLineItem.new(
      quantity: quantity,
      item_id: kit_item.id,
      item_value_in_cents: kit_item.value_in_cents,
      to_storage_location: storage_location,
      from_storage_location: nil
    ))
    items
  end

  def self.publish(kit_item, storage_location, quantity)
    create!(
      eventable: kit_item,
      group_id: "kit-allocate-#{kit_item.id}-#{SecureRandom.hex}",
      organization_id: kit_item.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        items: event_line_items(kit_item, storage_location, quantity)
      )
    )
  end
end
