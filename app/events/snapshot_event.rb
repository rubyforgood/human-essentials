class SnapshotEvent < Event
  serialize :data, coder: EventTypes::StructCoder.new(EventTypes::Inventory)

  # @param record [#organization_id, #created_at]
  # @return [SnapshotEvent, nil] the intervening snapshot event or null if there aren't any
  def self.intervening(record)
    where(organization_id: record.organization_id, event_time: record.created_at..).
      order('created_at desc').
      first
  end

  # @param organization [Organization]
  def self.publish(organization)
    inventory = InventoryAggregate.inventory_for(organization.id)
    create(
      eventable: organization,
      organization_id: organization.id,
      event_time: Time.zone.now,
      data: inventory
    )
  end
end
