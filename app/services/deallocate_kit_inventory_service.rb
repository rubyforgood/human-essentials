class DeallocateKitInventoryService
  attr_reader :kit, :storage_location, :error

  def initialize(kit, storage_location = nil)
    @kit = kit
    @storage_location = storage_location
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

  def validate_storage_location
    raise Errors::StorageLocationDoesNotMatch if storage_location.organization != kit.organization
  end

  def deallocate_inventory_items
    ActiveRecord::Base.transaction do
      storage_location.increase_inventory(kit)
    end
  end

  def set_error(error)
    @error = error.message
  end
end
