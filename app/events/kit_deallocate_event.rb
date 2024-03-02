class KitDeallocateEvent < Event
  def self.event_line_items(kit, storage_location, quantity)
    items = kit.line_items.map do |item|
      EventTypes::EventLineItem.new(
        quantity: item.quantity * quantity,
        item_id: item.item_id,
        item_value_in_cents: item.item.value_in_cents,
        to_storage_location: storage_location.id,
        from_storage_location: nil
      )
    end
    items.push(EventTypes::EventLineItem.new(
      quantity: quantity,
      item_id: kit.item.id,
      item_value_in_cents: kit.item.value_in_cents,
      from_storage_location: storage_location.id,
      to_storage_location: nil
    ))
    items
  end

  def self.publish(kit, storage_location, quantity)
    create(
      eventable: kit,
      group_id: "kit-deallocate-#{kit.id}-#{SecureRandom.hex}",
      organization_id: kit.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        items: event_line_items(kit, storage_location, quantity)
      )
    )
  end
end
