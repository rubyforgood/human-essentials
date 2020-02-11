def setup_storage_location(storage_location, *items)
  if items.empty?
    items << create(:item, organization: @organization)
    items << create(:item, organization: @organization)
    items << create(:item, organization: @organization)
  end

  items.each do |item|
    create(:inventory_item, storage_location: storage_location, item: item, quantity: 50)
  end
end
