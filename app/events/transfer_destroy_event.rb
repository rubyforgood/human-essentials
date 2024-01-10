class TransferDestroyEvent < Event
  # @param transfer [Transfer]
  def self.publish(transfer)
    create(
      eventable: transfer,
      group_id: "transfer-destroy-#{transfer.id}-#{SecureRandom.hex}",
      organization_id: transfer.organization_id,
      event_time: Time.zone.now,
      data: EventTypes::InventoryPayload.new(
        items: EventTypes::EventLineItem.zeroed_line_items(transfer.line_items,
          to: transfer.to.id,
          from: transfer.from.id)
      )
    )
  end
end
