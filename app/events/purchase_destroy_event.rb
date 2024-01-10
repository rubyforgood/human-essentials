class PurchaseDestroyEvent < Event
  # @param purchase [Purchase]
  def self.publish(purchase)
    create(
      eventable: purchase,
      group_id: "purchase-destroy-#{purchase.id}-#{SecureRandom.hex}",
      organization_id: purchase.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        items: EventTypes::EventLineItem.zeroed_line_items(purchase.line_items, to: purchase.storage_location_id)
      )
    )
  end
end
