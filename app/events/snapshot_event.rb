class SnapshotEvent < Event
  serialize :data, coder: EventTypes::StructCoder.new(EventTypes::Inventory)

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
