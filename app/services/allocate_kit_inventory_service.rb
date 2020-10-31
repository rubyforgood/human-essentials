class AllocateKitInventoryService
  attr_reader :kit, :storage_location, :increase_by, :error

  def initialize(kit:, storage_location:, increase_by:)
    @kit = kit
    @storage_location = storage_location
    @increase_by = increase_by
  end

  def allocate
    validate_storage_location
    allocate_inventory_items_and_increase_kit_quantity if error.nil?
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
