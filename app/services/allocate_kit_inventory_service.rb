class AllocateKitInventoryService
  attr_reader :kit, :storage_location, :increase_by, :error

  def initialize(kit:, storage_location:, increase_by:)
    @kit = kit
    @storage_location = storage_location
    @increase_by = increase_by
  end

  def allocate
    validate_storage_location
    if error.nil?
      allocate_inventory_items_and_increase_kit_quantity
      KitAllocateEvent.publish(@kit, @storage_location, @increase_by)
    end
  rescue Errors::InsufficientAllotment => e
    kit.line_items.assign_insufficiency_errors(e.insufficient_items)
    Rails.logger.error "[!] #{self.class.name} failed because of Insufficient Allotment #{kit.organization.short_name}: #{kit.errors.full_messages} [#{e.message}]"
    set_error(e)
  rescue StandardError => e
    Rails.logger.error "[!] #{self.class.name} failed to allocate items for a kit #{kit.name}: #{storage_location.errors.full_messages} [#{e.inspect}]"
    set_error(e)
  ensure
    return self
  end

  private

  def validate_storage_location
    raise Errors::StorageLocationDoesNotMatch if storage_location.organization != kit.organization
  end

  def allocate_inventory_items_and_increase_kit_quantity
    ActiveRecord::Base.transaction do
      storage_location.decrease_inventory(kit_content)
      storage_location.increase_inventory(associated_kit_item)
      allocate_inventory_in_and_inventory_out
    end
  end

  def allocate_inventory_in_and_inventory_out
    kit_allocation_types = ["inventory_in", "inventory_out"]
    kit_allocation_types.each do |kit_allocation_type|
      kit_allocation = KitAllocation.find_or_create_by!(storage_location_id: storage_location.id, kit_id: kit.id,
        organization_id: kit.organization.id, kit_allocation_type: kit_allocation_type)
      line_items = kit_allocation.line_items
      multiply_by = (kit_allocation_type == "inventory_out") ? -1 : 1
      if line_items.present?
        kit_content.each_with_index do |line_item, index|
          line_item_record = line_items[index]
          new_quantity = line_item_record[:quantity] + line_item[:quantity].to_i * multiply_by
          line_item_record.update!(quantity: new_quantity)
        end
      else
        kit_content.each do |line_item|
          kit_allocation.line_items.create!(item_id: line_item[:item_id], quantity: line_item[:quantity].to_i * multiply_by)
        end
      end
    end
  end

  def set_error(error)
    @error = error.message
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
