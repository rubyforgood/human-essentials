json.array! @items do |item|
  json.item_id item.item_id
  json.item_name item.name
  json.quantity item.quantity
end
