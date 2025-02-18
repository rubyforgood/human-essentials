class InventoryCheckService
  attr_reader :minimum_alert, :recommended_alert

  def initialize(distribution)
    @distribution = distribution
    @minimum_alert = nil
    @recommended_alert = nil
  end

  def call
    @inventory = View::Inventory.new(@distribution.organization_id)
    unless items_below_minimum_quantity.empty?
      set_minimum_alert
    end

    unless deduplicate_items_below_recommended_quantity.empty?
      set_recommended_alert
    end

    self
  end

  def set_minimum_alert
    @minimum_alert = "The following items have fallen below the minimum " \
      "on hand quantity, bank-wide: #{items_below_minimum_quantity.map(&:name).sort.join(", ")}"
  end

  def set_recommended_alert
    @recommended_alert = "The following items have fallen below the recommended " \
      "on hand quantity, bank-wide: #{deduplicate_items_below_recommended_quantity.map(&:name).sort.join(", ")}"
  end

  def items_below_minimum_quantity
    # Done this way to prevent N+1 query on items
    unless @items_below_minimum_quantity
      item_ids = @distribution.line_items.select do |line_item|
        quantity = @inventory.quantity_for(item_id: line_item.item_id)
        quantity < (line_item.item.on_hand_minimum_quantity || 0)
      end.map(&:item_id)

      @items_below_minimum_quantity = Item.find(item_ids)
    end

    @items_below_minimum_quantity
  end

  def items_below_recommended_quantity
    # Done this way to prevent N+1 query on items
    unless @items_below_recommended_quantity
      item_ids = @distribution.line_items.select do |line_item|
        quantity = @inventory.quantity_for(item_id: line_item.item_id)
        quantity < (line_item.item.on_hand_recommended_quantity || 0)
      end.map(&:item_id)

      @items_below_recommended_quantity = Item.find(item_ids)
    end

    @items_below_recommended_quantity
  end

  def deduplicate_items_below_recommended_quantity
    items_below_recommended_quantity - items_below_minimum_quantity
  end
end
