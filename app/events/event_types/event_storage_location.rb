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
      items[item_id] = EventTypes::EventItem.new(item_id: item_id, quantity: quantity, storage_location_id: id)
    end

    # @param item_id [Integer]
    # @param quantity [Integer]
    # @param validate [Boolean]
    def reduce_inventory(item_id, quantity, validate: true)
      if validate
        if items[item_id].nil?
          raise "Item #{item_id} not found in storage location #{id}"
        end
        if items[item_id].quantity < quantity
          raise "Could not reduce quantity by #{quantity} for item #{item_id} in storage location #{id} - current quantity is #{items[item_id].quantity}"
        end
      end
      current_quantity = items[item_id]&.quantity || 0
      items[item_id] = EventTypes::EventItem.new(item_id: item_id,
        storage_location_id: id,
        quantity: current_quantity - quantity)
    end

    # @param item_id [Integer]
    # @param quantity [Integer]
    def add_inventory(item_id, quantity)
      current_quantity = items[item_id]&.quantity || 0
      items[item_id] = EventTypes::EventItem.new(item_id: item_id,
        storage_location_id: id,
        quantity: current_quantity + quantity)
    end
  end
end
