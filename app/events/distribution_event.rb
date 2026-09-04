class DistributionEvent < Event
  serialize :data, coder: EventTypes::StructCoder.new(EventTypes::DistributionPayload)

  # @param distribution [Distribution]
  def self.publish(distribution)
    create(
      eventable: distribution,
      group_id: "dist-#{distribution.id}-#{SecureRandom.hex}",
      organization_id: distribution.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::DistributionPayload.new(
        reserves_inventory: Flipper.enabled?(:reserved_inventory, distribution.organization) && distribution.scheduled?,
        items: EventTypes::EventLineItem.from_line_items(distribution.line_items, from: distribution.storage_location_id)
      )
    )
  end
end
