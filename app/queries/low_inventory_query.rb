class LowInventoryQuery
  def self.call(organization)
    inventory = View::Inventory.new(organization.id)
    items = inventory.all_items.uniq(&:item_id)

    low_inventory_items = []
    items.each do |item|
      quantity = inventory.quantity_for(item_id: item.id)
      if quantity < item.on_hand_minimum_quantity.to_i || quantity < item.on_hand_recommended_quantity.to_i
        low_inventory_items.push({
          id: item.id,
          name: item.name,
          on_hand_minimum_quantity: item.on_hand_minimum_quantity,
          on_hand_recommended_quantity: item.on_hand_recommended_quantity,
          total_quantity: quantity
        })
      end
    end

    low_inventory_items.sort_by { |item| item[:name] }
  end
end
