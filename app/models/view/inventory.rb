module Types
  include Dry.Types()
end

module View
  # A wrapper around event-driven InventoryAggregate for use in views.
  class Inventory
    class ViewInventoryItem < EventTypes::EventItem
      attribute :db_item, Types::Nominal::Any
      delegate(*Item.column_names.map(&:to_sym), to: :db_item)
    end

    attr_accessor :inventory, :organization_id
    delegate :storage_locations, to: :inventory

    # @param event_time [ActiveSupport::TimeWithZone]
    # @return [Boolean]
    def self.within_snapshot?(organization_id, event_time)
      return true if event_time.blank?

      event = SnapshotEvent.where(organization_id: organization_id).first
      event && event.created_at < event_time
    end

    # @param organization_id [Integer]
    # @param storage_location_id [Integer]
    # @param event_time [ActiveSupport::TimeWithZone]
    # @return [Array<ViewInventoryItem>]
    def self.legacy_inventory_for_storage_location(organization_id, storage_location_id, event_time)
      items = Organization.find(organization_id).inventory_items.where(storage_location_id: storage_location_id)
      items.map do |item|
        ViewInventoryItem.new(
          item_id: item.item_id,
          quantity: item.paper_trail.version_at(event_time)&.quantity || 0,
          storage_location_id: storage_location_id,
          db_item: item.item
        )
      end
    end

    # @param organization_id [Integer]
    # @param event_time [DateTime]
    def initialize(organization_id, event_time: nil)
      self.organization_id = organization_id
      reload(event_time)
    end

    # @param event_time [DateTime]
    def reload(event_time = nil)
      @inventory = InventoryAggregate.inventory_for(organization_id, event_time: event_time)
      @items = Item.where(organization_id: organization_id).active
      @db_storage_locations = StorageLocation.where(organization_id: organization_id).active_locations
      load_item_details
    end

    # @param id [Integer]
    # @return [StorageLocation]
    def storage_location_name(id)
      @db_storage_locations.find { |loc| loc.id == id }&.name
    end

    # @param storage_location_id [Integer]
    # @param include_omitted [Boolean]
    # @return [Array<EventTypes::EventItem>]
    def items_for_location(storage_location_id, include_omitted: false)
      items = @inventory.storage_locations[storage_location_id]
        &.items
        &.values
        &.select { |i| i.quantity.positive? } || []
      if include_omitted
        db_items = Item.active.where(organization_id: @inventory.organization_id).where.not(id: items.map(&:item_id))
        zero_items = db_items.map do |item|
          ViewInventoryItem.new(
            item_id: item.id,
            quantity: 0,
            storage_location_id: storage_location_id,
            db_item: item
          )
        end
        items.concat(zero_items)
      end
      items.sort_by(&:name)
    end

    # @param storage_location [StorageLocation]
    # @param include_omitted [Boolean]
    # @return [Array<EventTypes::EventItem>]
    def self.items_for_location(storage_location, include_omitted: false)
      new(storage_location.organization_id).items_for_location(storage_location.id,
        include_omitted: include_omitted)
    end

    # @param organization_id [Integer]
    # @return [Integer]
    def self.total_inventory(organization_id)
      new(organization_id)
        .storage_locations
        .values
        .map { |loc| loc.items.values }
        .flatten
        .map(&:quantity)
        .sum
    end

    # @param storage_location [Integer]
    # @param item_id [Integer]
    # @return [Integer]
    def quantity_for(storage_location: nil, item_id: nil)
      return 0 if storage_location.nil? && item_id.nil?

      if storage_location
        if item_id
          @inventory.storage_locations[storage_location.to_i]&.items&.dig(item_id.to_i)&.quantity || 0
        else
          @inventory.storage_locations[storage_location.to_i]&.items&.values&.map(&:quantity)&.sum || 0
        end
      elsif item_id
        @inventory.storage_locations.values.map { |loc| loc&.items&.[](item_id.to_i)&.quantity }.compact.sum
      end
    end

    # @param item_id [Integer]
    # @return [Array<Integer>]
    def storage_locations_for_item(item_id)
      @inventory.storage_locations.values.select { |sl| sl.items[item_id]&.quantity&.positive? }.map(&:id)
    end

    # @param storage_location [Integer]
    # @return [Float]
    def total_value_in_dollars(storage_location: nil)
      return 0.0 if @inventory.storage_locations[storage_location].nil?
      total = @inventory.storage_locations[storage_location].items.values
        .map { |i| i.value_in_cents ? i.quantity * i.value_in_cents : 0 }.sum
      total.to_f / 100
    end

    # @return [Array<EventTypes::EventItem>]
    def all_items
      @inventory.storage_locations.values.map { |loc| loc.items.values }.flatten.compact
    end

    def load_item_details
      @inventory.storage_locations.values.each do |loc|
        loc.items.delete_if do |_, item|
          db_item = @items.find { |i| i.id == item.item_id }
          next true if db_item.nil?

          loc.items[item.item_id] = ViewInventoryItem.new(
            item_id: item.item_id,
            storage_location_id: loc.id,
            quantity: item.quantity,
            db_item: db_item
          )
          false
        end
      end
    end
  end
end
