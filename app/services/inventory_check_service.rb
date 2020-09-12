class InventoryCheckService
  attr_reader :error, :alert

  def initialize(distribution)
    @distribution = distribution
    @alert = nil
    @error = nil
  end

  def call
    items_below_minimum_quantity = []
    items_below_recommended_quantity = []
    storage_location = @distribution.storage_location

    @distribution.line_items.each do |line_item|
      item = line_item.item
      inventory_item = item.inventory_items.where(storage_location_id: storage_location.id).first

      if inventory_item.quantity < item.on_hand_minimum_quantity
        items_below_minimum_quantity << item
      elsif item.on_hand_recommended_quantity.present? &&
          inventory_item.quantity < item.on_hand_recommended_quantity
        items_below_recommended_quantity << item
      end
    end

    unless items_below_minimum_quantity.empty?
      @error = "The following items have fallen below the minimum " \
        "on hand quantity: #{items_below_minimum_quantity.map(&:name).join(", ")}"
    end

    unless items_below_recommended_quantity.empty?
      @alert = "The following items have fallen below the recommended " \
        "on hand quantity: #{items_below_recommended_quantity.map(&:name).join(", ")}"
    end

    self
  end
end
