class LowInventoryQuery
  def self.call(organization)
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
