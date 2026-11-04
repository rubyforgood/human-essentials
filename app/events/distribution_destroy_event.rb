class DistributionDestroyEvent < Event
  serialize :data, coder: EventTypes::StructCoder.new(EventTypes::DistributionPayload)

  # @param distribution [Distribution]
  def self.publish(distribution)
    create(
      eventable: distribution,
      group_id: "dist-destroy-#{distribution.id}-#{SecureRandom.hex}",
      organization_id: distribution.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::DistributionPayload.new(
        reserves_inventory: false,
        items: EventTypes::EventLineItem.zeroed_line_items(distribution.line_items, from: distribution.storage_location_id)
      )
    )
  end
end
