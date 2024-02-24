def setup_storage_location(storage_location, *items)
  if items.empty?
    items << create(:item, organization: @organization)
    items << create(:item, organization: @organization)
    items << create(:item, organization: @organization)
  end

  TestInventory.create_inventory(storage_location.organization, {
    storage_location.id => items.map { |i| [i.id, 50] }
  })
end
