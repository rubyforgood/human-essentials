class LowInventoryQuery
  def self.call(organization)
    if Event.read_events?(organization)
      inventory = View::Inventory.new(organization.id)
      items = inventory.all_items

      low_inventory_items = []
      items.each do |item|
        quantity = inventory.quantity_for(item_id: item.id)
        if quantity < item.on_hand_minimum_quantity.to_i || quantity < item.on_hand_recommended_quantity.to_i
          low_inventory_items.push(OpenStruct.new(
            id: item.id,
            name: item.name,
            on_hand_minimum_quantity: item.on_hand_minimum_quantity,
            on_hand_recommended_quantity: item.on_hand_recommended_quantity,
            total_quantity: quantity
          ))
        end
      end

      low_inventory_items.sort_by { |item| item[:name] }

    else
      sql_query = <<-SQL
        SELECT
          items.id,
          items.name,
          items.on_hand_minimum_quantity,
          items.on_hand_recommended_quantity,
          sum(inventory_items.quantity) as total_quantity
        FROM inventory_items
        JOIN items ON items.id = inventory_items.item_id
        JOIN storage_locations ON storage_locations.id = inventory_items.storage_location_id
        WHERE storage_locations.organization_id = ?
        GROUP BY items.id, items.name, items.on_hand_minimum_quantity, items.on_hand_recommended_quantity
        HAVING sum(inventory_items.quantity) < items.on_hand_minimum_quantity
          OR sum(inventory_items.quantity) < items.on_hand_recommended_quantity
        ORDER BY items.name
      SQL

      sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, [sql_query, organization.id])
      ActiveRecord::Base.connection.execute(sanitized_sql).to_a
    end
  end
end
