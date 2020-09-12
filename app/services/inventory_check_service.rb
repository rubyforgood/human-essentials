class InventoryCheckService
  attr_reader :alert, :distribution

  def initialize(distribution)
    @distribution = distribution
    @alert = nil
  end

  def call
    items_below_minimum_quantity = []
    storage_location = @distribution.storage_location

    @distribution.line_items.each do |line_item|
      item = line_item.item
      inventory_item = item.inventory_items.where(storage_location_id: storage_location.id).first

      if inventory_item.quantity < item.on_hand_minimum_quantity
        items_below_minimum_quantity << item
      end
    end

    unless items_below_minimum_quantity.empty?
      @alert = "The following items have fallen below the minimum " \
        "on hand quantity: #{items_below_minimum_quantity.map(&:name).join(", ")}"
    end

    self
  end
end
