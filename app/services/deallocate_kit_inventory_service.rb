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
