class UpdateExistingEvent < Event
  class << self
    # @param line_items [Array<LineItem>]
    # @param storage_location [StorageLocation]
    # @param direction [Symbol]
    # @return [Hash<Integer, EventTypes::EventLineItem>]
    def item_quantities(line_items, storage_location, direction)
      line_items.to_h do |line_item|
        opts = (direction == :from) ?
                 {from: storage_location.id} :
                 {to: storage_location.id}
        [line_item.item_id, EventTypes::EventLineItem.from_line_item(line_item, **opts)]
      end
    end

    # @param previous [Hash<Integer, EventTypes::EventLineItem>]
    # @param current [Hash<Integer, EventTypes::EventLineItem>]
    # @return [Array<EventTypes::EventLineItem>]
    def diff(previous, current)
      previous.each do |id, event_item|
        previous[id] = if current[id]
          event_item.new(quantity: current[id].quantity - event_item.quantity)
        else
          event_item.new(quantity: -event_item.quantity)
        end
      end
      all_items = previous.values
      (current.keys - previous.keys).each do |id|
        all_items.push(current[id]) # it's been added
      end
      all_items
    end

    # @param itemizable [Itemizable]
    # @return [Symbol]
    def direction(itemizable)
      itemizable.is_a?(Distribution) ? :from : :to
    end

    # @param itemizable [Itemizable]
    def publish(itemizable, previous_line_items)
      dir = direction(itemizable)
      previous_items = item_quantities(previous_line_items, itemizable.storage_location, dir)
      current_items = item_quantities(itemizable.line_items, itemizable.storage_location, dir)
      diff_items = diff(previous_items, current_items)

      create(
        eventable: itemizable,
        group_id: "existing-#{itemizable.id}-#{SecureRandom.hex}",
        organization_id: itemizable.organization_id,
        event_time: Time.zone.now,
        data: EventTypes::InventoryPayload.new(
          items: diff_items
        )
      )
    end
  end
end
