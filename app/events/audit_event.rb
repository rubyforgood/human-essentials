class AuditEvent < Event
  serialize :data, coder: EventTypes::StructCoder.new(EventTypes::AuditPayload)

  # @param audit [Audit]
  def self.publish(audit)
    create(
      eventable: audit,
      group_id: "audit-#{audit.id}-#{SecureRandom.hex}",
      organization_id: audit.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::AuditPayload.new(
        storage_location_id: audit.storage_location_id,
        items: EventTypes::EventLineItem.from_line_items(audit.line_items, to: audit.storage_location_id)
      )
    )
  end
end
