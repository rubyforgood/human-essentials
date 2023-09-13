RSpec.describe InventoryAggregate do
  let(:organization) { FactoryBot.create(:organization) }
  let(:storage_location1) { FactoryBot.create(:storage_location, organization: organization)}
  let(:storage_location2) { FactoryBot.create(:storage_location, organization: organization)}
  let(:item1) { FactoryBot.create(:item, organization: organization)}
  let(:item2) { FactoryBot.create(:item, organization: organization)}
  let(:item3) { FactoryBot.create(:item, organization: organization)}

  describe 'individual events' do
    let(:inventory) do
      EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 30),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: 45, quantity: 50)
            })
        })
    end

    it 'should process a donation event' do
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 50, item: item1)
      donation.line_items << build(:line_item, quantity: 30, item: item2)
      DonationEvent.publish(donation)

      InventoryAggregate.handle(DonationEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 80),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 40),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: 45, quantity: 50)
            })
        }))
    end

    it 'should process a distribution event' do
      dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
      dist.line_items << build(:line_item, quantity: 20, item: item1)
      dist.line_items << build(:line_item, quantity: 5, item: item2)
      DistributionEvent.publish(dist)

      InventoryAggregate.handle(DistributionEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: 45, quantity: 50)
            })
        }))
    end

  end

  it 'should process multiple events' do
    donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
    donation.line_items << build(:line_item, quantity: 50, item: item1)
    donation.line_items << build(:line_item, quantity: 30, item: item2)
    DonationEvent.publish(donation)

    donation2 = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
    donation2.line_items << build(:line_item, quantity: 30, item: item1)
    DonationEvent.publish(donation2)

    donation3 = FactoryBot.create(:donation, organization: organization, storage_location: storage_location2)
    donation3.line_items << build(:line_item, quantity: 50, item: item2)
    DonationEvent.publish(donation3)

    # correction event
    donation3.line_items = [build(:line_item, quantity: 40, item: item2)]
    DonationEvent.publish(donation3)

    dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
    dist.line_items << build(:line_item, quantity: 10, item: item1)
    DistributionEvent.publish(dist)

    dist2 = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location2)
    dist2.line_items << build(:line_item, quantity: 15, item: item2)
    DistributionEvent.publish(dist2)

    inventory = described_class.inventory_for(organization.id)
    expect(inventory).to eq(EventTypes::Inventory.new(
      organization_id: organization.id,
      storage_locations: {
        storage_location1.id => EventTypes::EventStorageLocation.new(
          id: storage_location1.id,
          items: {
            item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 70),
            item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 30)
          }),
        storage_location2.id => EventTypes::EventStorageLocation.new(
          id: storage_location2.id,
          items: {
            item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 25)
          }
        )
      }
    ))

  end
end
