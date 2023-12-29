class TransferEvent < Event
  # @param transfer [Transfer]
  def self.publish(transfer)
    create(
      eventable: transfer,
      group_id: "transfer-#{transfer.id}",
      organization_id: transfer.organization_id,
      event_time: transfer.created_at,
      data: EventTypes::InventoryPayload.new(
        items: EventTypes::EventLineItem.from_line_items(transfer.line_items,
          from: transfer.from.id,
          to: transfer.to.id)
      )
    )
  end
end
