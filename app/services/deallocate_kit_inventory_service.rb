class DeallocateKitInventoryService
  attr_reader :error

  def initialize(kit:, storage_location:, decrease_by:)
    @kit = kit
    @storage_location = storage_location
    @decrease_by = decrease_by
  end

  def deallocate
    validate_storage_location
    deallocate_inventory_items if error.nil?
  rescue StandardError => e
    Rails.logger.error "[!] #{self.class.name} failed to allocate items for a kit #{kit.name}: #{storage_location.errors.full_messages} [#{e.inspect}]"
    set_error(e)
  ensure
    return self
  end

  private

  attr_reader :kit, :storage_location, :decrease_by

  def validate_storage_location
    raise Errors::StorageLocationDoesNotMatch if storage_location.organization != kit.organization
  end

  def deallocate_inventory_items
    ActiveRecord::Base.transaction do
      storage_location.increase_inventory(kit_content)
      storage_location.decrease_inventory(associated_kit_item)
      deallocate_inventory_in_and_inventory_out
    end
  end

  def deallocate_inventory_in_and_inventory_out
    kit_allocation_types = ["inventory_in", "inventory_out"]
    kit_allocation_types.each do |kit_allocation_type|
      kit_allocation = KitAllocation.find_by(storage_location_id: storage_location.id, kit_id: kit.id,
        organization_id: kit.organization.id, kit_allocation_type: kit_allocation_type)
      if kit_allocation.present?
        multiply_by = (kit_allocation_type == "inventory_out") ? 1 : -1
        line_items = kit_allocation.line_items
        kit_content.each_with_index do |line_item, index|
          line_item_record = line_items[index]
          new_quantity = line_item_record[:quantity] + line_item[:quantity].to_i * multiply_by
          if new_quantity.to_i == 0
            kit_allocation.destroy!
            break
          elsif kit_allocation_type == "inventory_out" && new_quantity.to_i > 0
            raise StandardError.new("Inconsistent inventory out")
          elsif kit_allocation_type == "inventory_in" && new_quantity.to_i < 0
            raise StandardError.new("Inconsistent inventory in")
          else
            line_item_record.update!(quantity: new_quantity)
          end
        end
      else
        raise Errors::KitAllocationNotExists
      end
    end
  end

  def set_error(error)
    @error = error.message
  end

  def kit_content
    kit.to_a.map do |item|
      item.merge({
                   quantity: item[:quantity] * decrease_by
                 })
    end
  end

  def associated_kit_item
    [
      {
        item_id: kit.item.id,
        quantity: decrease_by
      }
    ]
  end
end
