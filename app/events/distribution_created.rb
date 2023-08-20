class DistributionCreated < ApplicationEvent

  # @param distribution [Distribution]
  def self.publish(distribution)
    event = self.from_payload(EventTypes::InventoryPayload.new(
      organization_id: distribution.organization_id,
      partner_id: distribution.partner_id,
      items: EventTypes::EventLineItem.from_line_items(distribution.line_items, to: distribution.storage_location_id)
    ))
    Rails.configuration.event_store.publish(event, stream_name: "org-#{distribution.organization_id}")
  end
end
