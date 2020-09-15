class InventoryCheckService
  attr_reader :error, :alert

  def initialize(distribution)
    @distribution = distribution
    @alert = nil
    @error = nil
  end

  def call
    unless items_below_minimum_quantity.empty?
      set_error
    end

    unless deduplicate_items_below_recommended_quantity.empty?
      set_alert
    end

    self
  end

  def set_error
    @error = "The following items have fallen below the minimum " \
      "on hand quantity: #{items_below_minimum_quantity.map(&:name).sort.join(", ")}"
  end

  def set_alert
    @alert = "The following items have fallen below the recommended " \
      "on hand quantity: #{deduplicate_items_below_recommended_quantity.map(&:name).sort.join(", ")}"
  end

  def items_below_minimum_quantity
    # Done this way to prevent N+1 query on items
    unless @items_below_minimum_quantity
      item_ids = @distribution.line_items.select do |line_item|
        inventory_item = line_item.item.inventory_item_at(@distribution.storage_location.id)
        inventory_item.lower_than_on_hand_minimum_quantity?
      end.map(&:item_id)

      @items_below_minimum_quantity = Item.find(item_ids)
    end

    @items_below_minimum_quantity
  end

  def items_below_recommended_quantity
    # Done this way to prevent N+1 query on items
    unless @items_below_recommended_quantity
      item_ids = @distribution.line_items.select do |line_item|
        inventory_item = line_item.item.inventory_item_at(@distribution.storage_location.id)
        inventory_item.lower_than_on_hand_recommended_quantity?
      end.map(&:item_id)

      @items_below_recommended_quantity = Item.find(item_ids)
    end

    @items_below_recommended_quantity
  end

  def deduplicate_items_below_recommended_quantity
    items_below_recommended_quantity - items_below_minimum_quantity
  end
end
