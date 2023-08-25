class DistributionCreated < Event

  # @param distribution [Distribution]
  def self.publish(distribution)
    self.create!(
      organization_id: distribution.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        partner_id: distribution.partner_id,
        items: EventTypes::EventLineItem.from_line_items(distribution.line_items, to: distribution.storage_location_id)
      ).as_json
    )
  end
end
