class InventoryCheckService
  attr_reader :error, :alert

  def initialize(distribution)
    @distribution = distribution
    @alert = nil
    @error = nil
  end

  def call
    unless items_below_minimum_quantity.empty?
      @error = "The following items have fallen below the minimum " \
        "on hand quantity: #{items_below_minimum_quantity.map(&:name).join(", ")}"
    end

    unless deduplicate_items_below_recommended_quantity.empty?
      @alert = "The following items have fallen below the recommended " \
        "on hand quantity: #{deduplicate_items_below_recommended_quantity.map(&:name).join(", ")}"
    end

    self
  end

  def items_below_minimum_quantity
    @distribution.line_items.select do |line_item|
      inventory_item = line_item.item.inventory_item_at(@distribution.storage_location.id)
      inventory_item.lower_than_on_hand_minimum_quantity?
    end.map(&:item)
  end

  def items_below_recommended_quantity
    @distribution.line_items.select do |line_item|
      inventory_item = line_item.item.inventory_item_at(@distribution.storage_location.id)
      inventory_item.lower_than_on_hand_recommended_quantity?
    end.map(&:item)
  end

  def deduplicate_items_below_recommended_quantity
    items_below_recommended_quantity - items_below_minimum_quantity
  end
end
