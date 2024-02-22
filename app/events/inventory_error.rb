class InventoryError < StandardError
  # @return [Event]
  attr_accessor :event
  # @return [Integer]
  attr_accessor :item_id
  # @return [Integer]
  attr_accessor :storage_location_id

  # @param message [String]
  # @param item_id [Integer]
  # @param storage_location_id [Integer]
  def initialize(message, item_id, storage_location_id)
    super(message)
    self.item_id = item_id
    self.storage_location_id = storage_location_id
  end
end
