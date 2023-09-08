class AuditEvent < Event
  # @param audit [Audit]
  def self.publish(audit)
    self.create!(
      eventable: audit,
      organization_id: audit.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        replace: true,
        items: EventTypes::EventLineItem.from_line_items(audit.line_items, to: adjustment.storage_location_id)
      ).as_json
    )
  end

end
