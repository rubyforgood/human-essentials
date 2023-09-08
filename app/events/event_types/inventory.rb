module Types
  include Dry.Types()
end

module EventTypes
  class Inventory < Dry::Struct
    attribute :organization_id, Types::Integer
    attribute :storage_locations, Types::Hash.map(Types::Integer, EventTypes::EventStorageLocation)

    # @param organization_id [Integer]
    # @return [EventTypes::Inventory]
    def self.from(organization_id)
      org = Organization.find(organization_id)
      self.new(organization_id: organization_id,
               storage_locations: org.storage_locations.map { |s| [s.id, EventTypes::EventStorageLocation.from(s)] }.to_h)
    end

    def replace_item(item_id:, quantity:, location:)
      self.storage_locations[location] ||= EventTypes::EventStorageLocation.new(id: location, items: {})
      self.storage_locations[location].set_inventory(item_id, quantity)
    end

    def move_item(item_id:, quantity:, from_location: nil, to_location: nil, validate: true)
      if from_location
        if self.storage_locations[from_location].nil? && validate
          raise "Storage location #{from_location} not found!"
        end
        self.storage_locations[from_location] ||= EventTypes::EventStorageLocation.new(id: from_location, items: {})
        self.storage_locations[from_location].reduce_inventory(item_id, quantity, validate: validate)
      end
      if to_location
        self.storage_locations[to_location].add_inventory(item_id, quantity)
      end
    end

  end
end

