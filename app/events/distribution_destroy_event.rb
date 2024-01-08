class DistributionDestroyEvent < Event
  # @param distribution [Distribution]
  def self.publish(distribution)
    create(
      eventable: distribution,
      group_id: "dist-destroy-#{distribution.id}-#{SecureRandom.hex}",
      organization_id: distribution.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        items: EventTypes::EventLineItem.from_line_items(distribution.line_items, to: distribution.storage_location_id)
      )
    )
  end
end
