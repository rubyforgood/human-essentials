class InventoryError < StandardError
  # @return [Event]
  attr_accessor :event
end
