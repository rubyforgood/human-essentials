module Types
  include Dry.Types()
end

module EventDiffer
  # Used to indicate that a storage location exists in one source but not the other.
  class LocationDiff < Dry::Struct
    attribute :storage_location_id, Types::Integer
    attribute :database, Types::Bool
    attribute :aggregate, Types::Bool

    # @param options [Object]
    # @return [Hash]
    def as_json(options = nil)
      super.merge(type: "location")
    end
  end

  # Used to indicate that the quantity of an item in one source doesn't match the other.
  class ItemDiff < Dry::Struct
    attribute :storage_location_id, Types::Integer
    attribute :item_id, Types::Integer
    attribute :database, Types::Integer
    attribute :aggregate, Types::Integer

    # @param options [Object]
    # @return [Hash]
    def as_json(options = nil)
      super.merge(type: "item")
    end
  end

  class << self
    # @param locations [Array<StorageLocation>]
    # @param inventory [EventTypes::Inventory]
    # @return [Array<LocationDiff>]
    def check_location_ids(locations, inventory)
      db_ids = locations.map(&:id)
      inventory_ids = inventory.storage_locations.keys
      diffs = []
      (db_ids - inventory_ids).each do |id|
        diffs.push(LocationDiff.new(storage_location_id: id, database: true, aggregate: false))
      end
      (inventory_ids - db_ids).each do |id|
        diffs.push(LocationDiff.new(storage_location_id: id, database: false, aggregate: true))
      end
      diffs
    end

    # @param inventory_loc [EventTypes::EventStorageLocation]
    # @param db_loc [StorageLocation]
    # @return [Array<ItemDiff>]
    def check_items(inventory_loc, db_loc)
      diffs = []
      diffs += check_item_ids(inventory_loc, db_loc)
      db_loc.inventory_items.each do |db_item|
        inventory_item = inventory_loc.items[db_item.item_id]
        next if inventory_item.nil?

        if inventory_item.quantity != db_item.quantity
          diffs.push(ItemDiff.new(item_id: db_item.item_id,
            storage_location_id: db_loc.id,
            database: db_item.quantity,
            aggregate: inventory_item.quantity))
        end
      end
      diffs
    end

    # @param inventory_loc [EventTypes::EventStorageLocation]
    # @param db_loc [StorageLocation]
    # @return [Array<ItemDiff>]
    def check_item_ids(inventory_loc, db_loc)
      inventory_ids = inventory_loc.items.keys
      db_ids = db_loc.inventory_items.map(&:item_id)
      diffs = []
      (db_ids - inventory_ids).each do |id|
        item = db_loc.inventory_items.find { |f| f.item_id == id }
        diffs.push(ItemDiff.new(item_id: id, storage_location_id: db_loc.id, database: item&.quantity, aggregate: 0))
      end
      (inventory_ids - db_ids).each do |id|
        item = inventory_loc.items[id]
        diffs.push(ItemDiff.new(item_id: id, storage_location_id: db_loc.id, database: 0, aggregate: item.quantity))
      end
      diffs
    end

    # @param inventory [EventTypes::Inventory]
    # @return [Array<ItemDiff, LocationDiff>]
    def check_difference(inventory)
      diffs = []
      org = Organization.find(inventory.organization_id)
      locations = org.storage_locations.to_a
      diffs += check_location_ids(locations, inventory)
      locations.each do |db_loc|
        inventory_loc = inventory.storage_locations[db_loc.id]
        next if inventory_loc.nil?

        diffs += check_items(inventory_loc, db_loc)
      end
      diffs
    end
  end
end
