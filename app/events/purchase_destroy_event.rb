class PurchaseDestroyEvent < Event
  # @param purchase [Purchase]
  def self.publish(purchase)
    create(
      eventable: purchase,
      organization_id: purchase.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        items: EventTypes::EventLineItem.from_line_items(purchase.line_items, from: purchase.storage_location_id)
      )
    )
  end
end
