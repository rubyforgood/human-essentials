class AdjustmentEvent < Event
  # @param adjustment [Adjustment]
  def self.publish(adjustment)
    self.create!(
      eventable: adjustment,
      organization_id: adjustment.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        items: EventTypes::EventLineItem.from_line_items(adjustment.line_items, from: adjustment.storage_location_id)
      ).as_json
    )
  end

end
