class DonationDestroyEvent < Event
  # @param donation [Donation]
  def self.publish(donation)
    create(
      eventable: donation,
      group_id: "donation-destroy-#{donation.id}-#{SecureRandom.hex}",
      organization_id: donation.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        items: EventTypes::EventLineItem.zeroed_line_items(donation.line_items, to: donation.storage_location_id)
      )
    )
  end
end
