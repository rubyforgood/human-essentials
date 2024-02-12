class AdjustmentEvent < Event
  # @param adjustment [Adjustment]
  def self.publish(adjustment)
    create(
      eventable: adjustment,
      group_id: "adjustment-#{adjustment.id}-#{SecureRandom.hex}",
      organization_id: adjustment.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        items: EventTypes::EventLineItem.from_line_items(adjustment.line_items, to: adjustment.storage_location_id)
      )
    )
  end
end
