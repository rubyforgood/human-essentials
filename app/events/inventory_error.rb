class InventoryError < StandardError
  # @return [Event]
  attr_accessor :event

  # @param message [String]
  def initialize(message)
    super
  end
end
