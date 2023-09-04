class DonationCreated < Event

  serialize :data, EventTypes::StructCoder.new(EventTypes::DonationPayload)

  # @param donation [Donation]
  def self.publish(donation)
    self.create!(
      organization_id: donation.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::DonationPayload.new(
        money_raised: donation.money_raised,
        items: EventTypes::EventLineItem.from_line_items(donation.line_items, to: donation.storage_location_id)
      )
    )
  end

end
