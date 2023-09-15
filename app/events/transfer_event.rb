class TransferEvent < Event
  # @param transfer [Transfer]
  def self.publish(transfer)
    self.create(
      eventable: transfer,
      organization_id: transfer.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        items: EventTypes::EventLineItem.from_line_items(transfer.line_items,
                                                         from: transfer.from.id,
                                                         to: transfer.to.id)
      ).as_json
    )
  end

end
