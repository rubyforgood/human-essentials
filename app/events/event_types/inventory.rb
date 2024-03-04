module Types
  include Dry.Types()
end

module EventTypes
  class Inventory < Dry::Struct
    transform_keys(&:to_sym)
    attribute :organization_id, Types::Integer
    attribute :storage_locations, Types::Hash.map(Types::Coercible::Integer, EventTypes::EventStorageLocation)

    # @param organization_id [Integer]
    # @return [EventTypes::Inventory]
    def self.from(organization_id)
      org = Organization.find(organization_id)
      new(organization_id: organization_id,
        storage_locations: org.storage_locations.map { |s| [s.id, EventTypes::EventStorageLocation.from(s)] }.to_h)
    end

    # @param item_id [Integer]
    # @param quantity [Integer]
    # @param location [Integer]
    def set_item_quantity(item_id:, quantity:, location:)
      storage_locations[location] ||= EventTypes::EventStorageLocation.new(id: location, items: {})
      storage_locations[location].set_inventory(item_id, quantity)
    end

    # @param item_id [Integer]
    # @param quantity [Integer]
    # @param from_location [Integer]
    # @param to_location [Integer]
    # @param validate [Boolean]
    def move_item(item_id:, quantity:, from_location: nil, to_location: nil, validate: true)
      if quantity.negative?
        return move_item(item_id: item_id,
          quantity: -quantity,
          from_location: to_location,
          to_location: from_location,
          validate: validate)
      end
      if from_location
        if storage_locations[from_location].nil? && validate
          raise "Storage location #{from_location} not found!"
        end
        storage_locations[from_location] ||= EventTypes::EventStorageLocation.new(id: from_location, items: {})
        storage_locations[from_location].reduce_inventory(item_id, quantity, validate: validate)
      end
      if to_location
        storage_locations[to_location] ||= EventTypes::EventStorageLocation.new(id: to_location, items: {})
        storage_locations[to_location].add_inventory(item_id, quantity)
      end
    end
  end
end
