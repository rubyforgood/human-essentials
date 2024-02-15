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
      ApplicationRecord.transaction do
        allocate_inventory_items_and_increase_kit_quantity
        KitAllocateEvent.publish(@kit, @storage_location.id, @increase_by)
      end
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
    allocate_inventory_in
    allocate_inventory_out
  end

  def allocate_inventory_out
    kit_allocation = KitAllocation.find_or_create_by!(storage_location_id: storage_location.id, kit_id: kit.id,
      organization_id: kit.organization.id, kit_allocation_type: "inventory_out")
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
      organization_id: kit.organization.id, kit_allocation_type: "inventory_in")
    line_items = kit_allocation.line_items
    if line_items.present?
      kit_item = line_items.first
      new_quantity = kit_item[:quantity] + increase_by
      kit_item.update!(quantity: new_quantity)
    else
      kit_allocation.line_items.create!(associated_kit_item)
    end
  end

  def set_error(error)
    @error = error.message
  end

  def kit_content
    kit.line_item_values.map do |item|
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
