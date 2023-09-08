module InventoryAggregate

  class << self

    # @param event_type [Class<Event>]
    def on(event_type, &block)
      @handlers ||= {}
      @handlers[event_type] = block
    end

    # @param organization_id
    # @return [EventTypes::Inventory]
    def inventory_for(organization_id)
      events = Event.for_organization(organization_id)
      inventory = EventTypes::Inventory.from(organization_id)
      events.group_by { |e| [e.eventable_type, e.eventable_id] }.each do |_, event_batch|
        last_event = event_batch.max_by(&:event_time)
        handle(last_event, inventory)
      end
      inventory
    end

    # @param event [Event]
    # @param inventory [Inventory]
    def handle(event, inventory)
      @handlers[event.class].call(event, inventory)
    end

    # @param payload [EventTypes::InventoryPayload]
    # @param inventory [EventTypes::Inventory]
    # @param validate [Boolean]
    def handle_inventory_event(payload, inventory, validate: true)
      payload.items.each do |line_item|
        inventory.move_item(item_id: line_item.item_id,
                            quantity: line_item.quantity,
                            from_location: line_item.from_storage_location,
                            to_location: line_item.to_storage_location,
                            validate: validate
                            )
      end

    end

  end

  on DonationEvent do |event, inventory|
    handle_inventory_event(event.data, inventory, validate: false)
  end

  on DistributionEvent do |event, inventory|
    handle_inventory_event(event.data, inventory, validate: false)
  end

end
