json.array! @storage_location.inventory_items do |inventory|
  json.item_id inventory.item.id
  json.item_name inventory.item.name
  json.item_category inventory.item.category
  json.quantity inventory.quantity
end

