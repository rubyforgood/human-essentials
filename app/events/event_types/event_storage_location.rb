module Types
  include Dry.Types()
end

module EventTypes
  class EventStorageLocation < Dry::Struct
    transform_keys(&:to_sym)

    attribute :id, Types::Integer
    attribute :items, Types::Hash.map(Types::Coercible::Integer, EventTypes::EventItem)

    # @param storage_location [StorageLocation]
    # @return [EventTypes::EventStorageLocation]
    def self.from(storage_location)
      new(id: storage_location.id, items: {})
    end

    def reset!
      items.clear
    end

    # @param item_id [Integer]
    # @param quantity [Integer]
    def set_inventory(item_id, quantity)
      items[item_id] = EventTypes::EventItem.new(
        item_id: item_id,
        storage_location_id: id,
        quantity: quantity,
        reserved_quantity: items[item_id]&.reserved_quantity || 0
      )
    end

    # @param item_id [Integer]
    # @param quantity [Integer]
    # @param validate [Boolean]
    def reduce_inventory(item_id, quantity, validate: true)
      if validate
        current_quantity = items[item_id]&.quantity || 0
        if current_quantity < quantity
          raise InventoryActionError.new("Could not reduce quantity by #{quantity} - current quantity is #{current_quantity}",
            item_id,
            id)
        end
      end
      current_quantity = items[item_id]&.quantity || 0
      items[item_id] = EventTypes::EventItem.new(
        item_id: item_id,
        storage_location_id: id,
        quantity: current_quantity - quantity,
        reserved_quantity: items[item_id]&.reserved_quantity || 0
      )
    end

    # @param item_id [Integer]
    # @param quantity [Integer]
    def add_inventory(item_id, quantity)
      current_quantity = items[item_id]&.quantity || 0
      items[item_id] = EventTypes::EventItem.new(
        item_id: item_id,
        storage_location_id: id,
        quantity: current_quantity + quantity,
        reserved_quantity: items[item_id]&.reserved_quantity || 0
      )
    end

    # @param item_id [Integer]
    # @param quantity [Integer] positive to reserve, negative to release
    # @param validate [Boolean]
    def adjust_reserved(item_id, quantity, validate: true)
      current_quantity = items[item_id]&.reserved_quantity || 0
      if validate && (current_quantity + quantity).negative?
        raise InventoryActionError.new("Could not reduce reserved quantity by #{-quantity} - current reserved quantity is #{current_quantity}",
          item_id,
          id)
      end
      items[item_id] = EventTypes::EventItem.new(
        item_id: item_id,
        storage_location_id: id,
        quantity: items[item_id]&.quantity || 0,
        reserved_quantity: current_quantity + quantity
      )
    end
  end
end
