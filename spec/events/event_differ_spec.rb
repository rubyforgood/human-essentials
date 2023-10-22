RSpec.describe EventDiffer do
  let(:organization) { create(:organization) }
  let(:storage_location1) { create(:storage_location, organization: organization) }
  let(:storage_location2) { create(:storage_location, organization: organization) }
  let!(:storage_location3) { create(:storage_location, organization: organization) }
  let(:item1) { create(:item, organization: organization) }
  let(:item2) { create(:item, organization: organization) }
  let(:item3) { create(:item, organization: organization) }

  before(:each) do
    create(:inventory_item, item: item1, storage_location: storage_location1, quantity: 50)
    create(:inventory_item, item: item2, storage_location: storage_location1, quantity: 50)
    create(:inventory_item, item: item1, storage_location: storage_location2, quantity: 50)
  end

  it 'should return a full diff' do
    aggregate = EventTypes::Inventory.new(
      organization_id:   organization.id,
      storage_locations: {
        storage_location1.id => EventTypes::EventStorageLocation.new(
          id:    storage_location1.id,
          items: {
            item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 50), # no diff
            # missing item2
            item3.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 70) # added item3
          }
        ),
        storage_location2.id => EventTypes::EventStorageLocation.new(
          id:    storage_location2.id,
          items: {
            item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 60), # diff in quantity
            item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 40) # added item2
          }
        ),
        # missing storage_location3
        # added storage location that doesn't exist
        StorageLocation.count + 1 => EventTypes::EventStorageLocation.new(
          id:    StorageLocation.count + 1,
          items: {}
        )
      }
    )
    results   = EventDiffer.check_difference(aggregate)
    expect(results.as_json).to contain_exactly(
                                 { "aggregate"           => false,
                                   "database"            => true,
                                   "storage_location_id" => storage_location3.id,
                                   :type                 => "location" },
                                 { "aggregate"           => true,
                                    "database"            => false,
                                    "storage_location_id" => StorageLocation.count + 1,
                                    :type                 => "location" },
                                 { "aggregate"           => 0,
                                    "database"            => 50,
                                    "item_id"             => item2.id,
                                    "storage_location_id" => storage_location1.id,
                                    :type                 => "item" },
                                 { "aggregate"           => 70,
                                    "database"            => 0,
                                    "item_id"             => item3.id,
                                    "storage_location_id" => storage_location1.id,
                                    :type                 => "item" },
                                 { "aggregate"           => 40,
                                    "database"            => 0,
                                    "item_id"             => item2.id,
                                    "storage_location_id" => storage_location2.id,
                                    :type                 => "item" },
                                 { "aggregate"           => 60,
                                    "database"            => 50,
                                    "item_id"             => item1.id,
                                    "storage_location_id" => storage_location2.id,
                                    :type                 => "item" }
                               )
  end

end
