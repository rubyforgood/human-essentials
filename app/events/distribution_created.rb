class DistributionCreated < Event

  serialize :data, EventTypes::StructCoder.new(EventTypes::InventoryPayload)

  # @param distribution [Distribution]
  def self.publish(distribution)
    self.create!(
      organization_id: distribution.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        items: EventTypes::EventLineItem.from_line_items(distribution.line_items, from: distribution.storage_location_id)
      ).as_json
    )
  end

end
