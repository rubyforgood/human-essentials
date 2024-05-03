module InventoryAggregate
  class << self
    # @param event_types [Array<Class<Event>>]
    def on(*event_types, &block)
      @handlers ||= {}
      event_types.each do |event_type|
        @handlers[event_type] = block
      end
    end

    # @param organization_id [Integer]
    # @param event_time [DateTime]
    # @param validate [Boolean]
    # @return [EventTypes::Inventory]
    def inventory_for(organization_id, event_time: nil, validate: false)
      last_snapshot = Event.most_recent_snapshot(organization_id)

      # ignore all other snapshots as they are considered "unusable" - see most_recent_snapshot method
      events = Event.for_organization(organization_id).without_snapshots
      if last_snapshot # all previous events can be ignored
        events = events.where("event_time > ?", last_snapshot.event_time)
      end

      if event_time && (!last_snapshot || event_time > last_snapshot.event_time)
        events = events.where("event_time <= ?", event_time)
      end

      events = events.to_a
      events.unshift(last_snapshot) if last_snapshot

      inventory = EventTypes::Inventory.from(organization_id)
      event_hash = {}
      events.group_by(&:group_id).each do |_, event_batch|
        last_grouped_event = event_batch.max_by(&:updated_at)
        # don't do grouping for UpdateExistingEvents
        if event_batch.any? { |e| e.is_a?(UpdateExistingEvent) }
          handle(last_grouped_event, inventory, validate: validate)
          next
        end
        previous_event = event_hash[last_grouped_event.eventable]
        event_hash[last_grouped_event.eventable] = last_grouped_event
        handle(last_grouped_event, inventory, validate: validate, previous_event: previous_event)
      end
      inventory
    end

    # @param event [Event]
    # @param inventory [Inventory]
    # @param previous_event [Event]
    # @param validate [Boolean]
    def handle(event, inventory, validate: false, previous_event: nil)
      handler = @handlers[event.class]
      if handler.nil?
        Rails.logger.warn("No handler found for #{event.class}, skipping")
        return
      end
      handler.call(event, inventory, validate: validate, previous_event: previous_event)
    end

    # @param payload [EventTypes::InventoryPayload]
    # @param inventory [EventTypes::Inventory]
    # @param validate [Boolean]
    # @param previous_event [Event]
    def handle_inventory_event(payload, inventory, validate: true, previous_event: nil)
      payload.items.each do |line_item|
        quantity = line_item.quantity
        if previous_event
          previous_item = previous_event.data.items.find { |i| i.same_item?(line_item) }
          quantity -= previous_item.quantity if previous_item
        end
        inventory.move_item(item_id: line_item.item_id,
          quantity: quantity,
          from_location: line_item.from_storage_location,
          to_location: line_item.to_storage_location,
          validate: validate)
      end
      # remove the quantity from any items that are now missing
      previous_event&.data&.items&.each do |previous_item|
        new_item = payload.items.find { |i| i.same_item?(previous_item) }
        if new_item.nil?
          inventory.move_item(item_id: previous_item.item_id,
            quantity: previous_item.quantity,
            from_location: previous_item.to_storage_location,
            to_location: previous_item.from_storage_location,
            validate: validate)
        end
      end
    end

    # @param payload [EventTypes::InventoryPayload]
    # @param inventory [EventTypes::Inventory]
    def handle_audit_event(payload, inventory)
      payload.items.each do |line_item|
        inventory.set_item_quantity(item_id: line_item.item_id,
          quantity: line_item.quantity,
          location: line_item.to_storage_location)
      end
    end
  end

  # ignore previous events
  on KitAllocateEvent, KitDeallocateEvent do |event, inventory, validate: false, previous_event: nil|
    handle_inventory_event(event.data, inventory, validate: validate)
  rescue InventoryError => e
    e.event = event
    raise e
  end

  # diff previous event
  on DonationEvent, DistributionEvent, AdjustmentEvent, PurchaseEvent,
    TransferEvent, DistributionDestroyEvent, DonationDestroyEvent,
    PurchaseDestroyEvent, TransferDestroyEvent,
    UpdateExistingEvent do |event, inventory, validate: false, previous_event: nil|
    handle_inventory_event(event.data, inventory, validate: validate, previous_event: previous_event)
  rescue InventoryError => e
    e.event = event
    raise e
  end

  on AuditEvent do |event, inventory, validate: false, previous_event: nil|
    handle_audit_event(event.data, inventory)
  end

  on SnapshotEvent do |event, inventory, validate: false, previous_event: nil|
    inventory.storage_locations.clear
    inventory.storage_locations.merge!(event.data.storage_locations)
  end
end
