class BringInventoryInAndOutToInvetoryLevel < ActiveRecord::Migration[7.0]
  # this data migration is for the perpose to bring inventory_in and inventory_out
  # to current inventory level so that in-case of kit de-allocation we do not face "inconsistency inventory in" error
  class AllocationService
    attr_reader :kit, :storage_location, :increase_by, :error

    def initialize(kit:, storage_location:, increase_by:)
      @kit = kit
      @storage_location = storage_location
      @increase_by = increase_by
    end

    def allocate
      ActiveRecord::Base.transaction do
        allocate_inventory_in
        allocate_inventory_out
      rescue => e
        Rails.logger.debug "Error: #{e}"
        raise ActiveRecord::Rollback
      end
    end

    def allocate_inventory_out
      kit_allocation = KitAllocation.find_or_create_by!(storage_location_id: storage_location.id, kit_id: kit.id,
        organization_id: kit.organization.id, inventory: "inventory_out")
      line_items = kit_allocation.line_items
      if line_items.present?
        kit_content.each_with_index do |line_item, index|
          line_item_record = line_items[index]
          new_quantity = line_item_record[:quantity] + line_item[:quantity].to_i * -1
          line_item_record.update!(quantity: new_quantity)
        end
      else
        kit_content.each do |line_item|
          kit_allocation.line_items.create!(item_id: line_item[:item_id], quantity: line_item[:quantity].to_i * -1)
        end
      end
    end

    def allocate_inventory_in
      kit_allocation = KitAllocation.find_or_create_by!(storage_location_id: storage_location.id, kit_id: kit.id,
        organization_id: kit.organization.id, inventory: "inventory_in")
      line_items = kit_allocation.line_items
      if line_items.present?
        kit_item = line_items.first
        new_quantity = kit_item[:quantity] + increase_by
        kit_item.update!(quantity: new_quantity)
      else
        kit_allocation.line_items.create!(associated_kit_item)
      end
    end

    def kit_content
      kit.to_a.map do |item|
        item.merge({
          quantity: item[:quantity] * increase_by
        })
      end
    end

    def associated_kit_item
      [
        {
          item_id: kit.item.id,
          quantity: increase_by
        }
      ]
    end
  end

  def up
    StorageLocation.all.each do |location|
      location.inventory_items.select { |inventory_item| inventory_item.item.partner_key == "kit" }.each do |inventory_item|
        kit_quantity = inventory_item.quantity
        kit_item = inventory_item.item
        kit = kit_item.kit
        if kit.present?
          service = AllocationService.new(storage_location: location, kit: kit, increase_by: kit_quantity)
          Rails.logger.debug "=====================================================>>>"
          Rails.logger.debug "allocating kit_id: #{kit.id} kit_name: #{kit.name} kit_quantity: #{kit_quantity}"
          service.allocate
        else
          Rails.logger.debug "=====================================================>>>"
          Rails.logger.debug "kit not exist"
        end
      end
    end
  end

  def down
  end
end
