RSpec.describe InventoryAggregate do
  let(:organization) { FactoryBot.create(:organization, :with_items) }
  let(:storage_location1) { FactoryBot.create(:storage_location, organization: organization) }
  let(:storage_location2) { FactoryBot.create(:storage_location, organization: organization) }
  let(:item1) { FactoryBot.create(:item, organization: organization) }
  let(:item2) { FactoryBot.create(:item, organization: organization) }
  let(:item3) { FactoryBot.create(:item, organization: organization) }

  describe "individual events" do
    let!(:inventory) do
      TestInventory.create_inventory(organization,
        {
          storage_location1.id => {
            item1.id => 30,
            item2.id => 10,
            item3.id => 40
          },
          storage_location2.id => {
            item2.id => 10,
            item3.id => 50
          }
        })
      InventoryAggregate.inventory_for(organization.id)
    end

    it "should process a donation event" do
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 50, item: item1, itemizable: donation)
      donation.line_items << build(:line_item, quantity: 30, item: item2, itemizable: donation)
      DonationEvent.publish(donation)

      # 30 + 50 = 80, 10 + 30 = 40
      described_class.handle(DonationEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 80, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 40, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should process a distribution event" do
      dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
      dist.line_items << build(:line_item, quantity: 20, item: item1, itemizable: dist)
      dist.line_items << build(:line_item, quantity: 5, item: item2, itemizable: dist)
      DistributionEvent.publish(dist)

      # 30 - 20 = 10, 10 - 5 = 5
      described_class.handle(DistributionEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should process a donation event after a new storage location is created" do
      new_loc = FactoryBot.create(:storage_location, organization: organization)
      donation = FactoryBot.create(:donation, organization: organization, storage_location: new_loc)
      donation.line_items << build(:line_item, quantity: 20, item: item1, itemizable: donation)
      donation.line_items << build(:line_item, quantity: 5, item: item2, itemizable: donation)
      DonationEvent.publish(donation)

      # 30 - 20 = 10, 10 - 5 = 5
      described_class.handle(DonationEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 30, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          ),
          new_loc.id => EventTypes::EventStorageLocation.new(
            id: new_loc.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 20, storage_location_id: new_loc.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5, storage_location_id: new_loc.id)
            }
          )
        }
      ))
    end

    it "should process a donation destroyed event" do
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 20, item: item1, itemizable: donation)
      donation.line_items << build(:line_item, quantity: 5, item: item2, itemizable: donation)
      DonationEvent.publish(donation)
      DonationDestroyEvent.publish(donation)

      described_class.handle(DonationEvent.last, inventory)
      described_class.handle(DonationDestroyEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 30, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should process a purchase destroyed event" do
      purchase = FactoryBot.create(:purchase, organization: organization, storage_location: storage_location1)
      purchase.line_items << build(:line_item, quantity: 20, item: item1, itemizable: purchase)
      purchase.line_items << build(:line_item, quantity: 5, item: item2, itemizable: purchase)
      PurchaseEvent.publish(purchase)
      PurchaseDestroyEvent.publish(purchase)

      # 30 - 20 = 10, 10 - 5 = 5
      described_class.handle(PurchaseEvent.last, inventory)
      described_class.handle(PurchaseDestroyEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 30, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should process an adjustment event" do
      adjustment = FactoryBot.create(:adjustment, organization: organization, storage_location: storage_location1)
      adjustment.line_items << build(:line_item, quantity: 20, item: item1, itemizable: adjustment)
      adjustment.line_items << build(:line_item, quantity: -5, item: item2, itemizable: adjustment)
      AdjustmentEvent.publish(adjustment)

      # 30 + 20 = 50, 10 - 5 = 5
      described_class.handle(AdjustmentEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 50, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should process a purchase event" do
      purchase = FactoryBot.create(:purchase, organization: organization, storage_location: storage_location1)
      purchase.line_items << build(:line_item, quantity: 50, item: item1, itemizable: purchase)
      purchase.line_items << build(:line_item, quantity: 30, item: item2, itemizable: purchase)
      PurchaseEvent.publish(purchase)

      # 30 + 50 = 80, 10 + 30 = 40
      described_class.handle(PurchaseEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 80, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 40, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should process a distribution destroyed event" do
      dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
      dist.line_items << build(:line_item, quantity: 20, item: item1, itemizable: dist)
      dist.line_items << build(:line_item, quantity: 10, item: item2, itemizable: dist)
      DistributionEvent.publish(dist)
      DistributionDestroyEvent.publish(dist)

      # should be unchanged
      described_class.handle(DistributionEvent.last, inventory)
      described_class.handle(DistributionDestroyEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 30, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should process a transfer event" do
      transfer = FactoryBot.create(:transfer, organization: organization, from: storage_location1, to: storage_location2)
      transfer.line_items << build(:line_item, quantity: 20, item: item1, itemizable: transfer)
      transfer.line_items << build(:line_item, quantity: 5, item: item2, itemizable: transfer)
      TransferEvent.publish(transfer)

      # 30 - 20 = 10, 10 - 5 = 5
      # 0 + 20 = 20, 10 + 5 = 15
      described_class.handle(TransferEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 20, storage_location_id: storage_location2.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 15, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should process a transfer destroy event" do
      transfer = FactoryBot.create(:transfer, organization: organization, from: storage_location2, to: storage_location1)
      transfer.line_items << build(:line_item, quantity: 5, item: item2, itemizable: transfer)
      transfer.line_items << build(:line_item, quantity: 3, item: item3, itemizable: transfer)
      TransferEvent.publish(transfer)
      TransferDestroyEvent.publish(transfer)

      # should be unchanged
      described_class.handle(TransferEvent.last, inventory)
      described_class.handle(TransferDestroyEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 30, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should process an audit event" do
      audit = FactoryBot.create(:audit, organization: organization, storage_location: storage_location1)
      audit.line_items << build(:line_item, quantity: 20, item: item1, itemizable: audit)
      audit.line_items << build(:line_item, quantity: 10, item: item3, itemizable: audit)
      AuditEvent.publish(audit)

      described_class.handle(AuditEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 20, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 10, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should process a kit allocation event" do
      kit = FactoryBot.create(:kit, :with_item, organization: organization)

      kit.line_items = []
      kit.line_items << build(:line_item, quantity: 10, item: item1, itemizable: kit)
      kit.line_items << build(:line_item, quantity: 3, item: item2, itemizable: kit)
      KitAllocateEvent.publish(kit, storage_location1.id, 2)

      # 30 - (10*2) = 10, 10 - (3*2) = 4
      # 0 + 20 = 20, 10 + 5 = 15
      described_class.handle(KitAllocateEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 4, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40, storage_location_id: storage_location1.id),
              kit.item.id => EventTypes::EventItem.new(item_id: kit.item.id, quantity: 2, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should process a kit deallocation event" do
      kit = FactoryBot.create(:kit, :with_item, organization: organization)
      TestInventory.create_inventory(organization,
        {
          storage_location1.id => {
            item1.id => 30,
            item2.id => 10,
            item3.id => 40,
            kit.item.id => 3
          },
          storage_location2.id => {
            item2.id => 10,
            item3.id => 50
          }
        })
      inventory = InventoryAggregate.inventory_for(organization.id) # reload

      kit.line_items = []
      kit.line_items << build(:line_item, quantity: 20, item: item1, itemizable: kit)
      kit.line_items << build(:line_item, quantity: 5, item: item2, itemizable: kit)
      KitDeallocateEvent.publish(kit, storage_location1, 2)

      # 30 + (20*2) = 70, 10 + (5*2) = 20
      described_class.handle(KitDeallocateEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 70, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 20, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40, storage_location_id: storage_location1.id),
              kit.item.id => EventTypes::EventItem.new(item_id: kit.item.id, quantity: 1, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should process a snapshot event" do
      InventoryItem.delete_all

      storage_location1.inventory_items.create!(quantity: 5, item_id: item1.id)
      storage_location1.inventory_items.create!(quantity: 10, item_id: item2.id)
      storage_location2.inventory_items.create!(quantity: 15, item_id: item2.id)
      storage_location2.inventory_items.create!(quantity: 20, item_id: item3.id)
      SnapshotEvent.publish(organization)

      described_class.handle(SnapshotEvent.last, inventory)
      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 5, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 15, storage_location_id: storage_location2.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 20, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end
  end

  describe "multiple events" do
    it "should process multiple events" do
      item4 = FactoryBot.create(:item, organization: organization)
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 50, item: item1, itemizable: donation)
      donation.line_items << build(:line_item, quantity: 30, item: item2, itemizable: donation)
      DonationEvent.publish(donation)

      donation2 = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation2.line_items << build(:line_item, quantity: 30, item: item1, itemizable: donation)
      DonationEvent.publish(donation2)

      donation3 = FactoryBot.create(:donation, organization: organization, storage_location: storage_location2)
      donation3.line_items << build(:line_item, quantity: 50, item: item2, itemizable: donation)
      DonationEvent.publish(donation3)

      # correction event
      donation3.line_items = [build(:line_item, quantity: 40, item: item2, itemizable: donation)]
      donation3.line_items << build(:line_item, quantity: 50, item: item4, itemizable: donation)
      DonationEvent.publish(donation3)

      dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
      dist.line_items << build(:line_item, quantity: 10, item: item1, itemizable: dist)
      DistributionEvent.publish(dist)

      dist2 = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location2)
      dist2.line_items << build(:line_item, quantity: 15, item: item2, itemizable: dist)
      DistributionEvent.publish(dist2)

      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 70, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 30, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 25, storage_location_id: storage_location2.id),
              item4.id => EventTypes::EventItem.new(item_id: item4.id, quantity: 50, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should handle changing storage location" do
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 50, item: item2, itemizable: donation)
      DonationEvent.publish(donation)

      donation2 = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation2.line_items << build(:line_item, quantity: 50, item: item1, itemizable: donation)
      DonationEvent.publish(donation2)

      donation2.update!(storage_location_id: storage_location2.id)
      donation2.line_items = [build(:line_item, quantity: 30, item: item1, itemizable: donation)]
      DonationEvent.publish(donation2)

      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 0, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 50, storage_location_id: storage_location1.id)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 30, storage_location_id: storage_location2.id)
            }
          )
        }
      ))
    end

    it "should handle intervening audits" do
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 30, item: item1, itemizable: donation)
      DonationEvent.publish(donation)

      dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
      dist.line_items << build(:line_item, quantity: 10, item: item1, itemizable: dist)
      DistributionEvent.publish(dist)

      audit = FactoryBot.create(:audit, organization: organization, storage_location: storage_location1)
      audit.line_items << build(:line_item, quantity: 50, item: item1, itemizable: audit)
      AuditEvent.publish(audit)

      dist.line_items[0].quantity = 40 # this should be a NOW event and remove another 30
      DistributionEvent.publish(dist)

      inventory = described_class.inventory_for(organization.id, validate: true)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 20, storage_location_id: storage_location1.id)
            }
          )
        }
      ))
    end

    it "should handle timing correctly" do
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 30, item: item1, itemizable: donation)
      DonationEvent.publish(donation)

      dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
      dist.line_items << build(:line_item, quantity: 10, item: item1, itemizable: dist)
      DistributionEvent.publish(dist)

      # correction event
      donation.line_items[0].quantity = 20
      DonationEvent.publish(donation)

      inventory = described_class.inventory_for(organization.id, validate: true)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10, storage_location_id: storage_location1.id)
            }
          )
        }
      ))
    end

    # NOTE: as of now, this behavior is not necessary since all our events are "now". However, we
    # know this might change in the future if we allow rewriting history due to clerical errors.
    # This was already coded, so we might as well leave it in so we don't shoot ourselves in the
    # foot later.
    it "should ignore unusable snapshots" do
      freeze_time do
        donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
        donation.line_items << build(:line_item, quantity: 50, item: item1, itemizable: donation)
        donation.line_items << build(:line_item, quantity: 30, item: item2, itemizable: donation)
        DonationEvent.publish(donation)

        travel 1.minute
        SnapshotEvent.publish_from_events(organization)

        # check inventory at this point
        inventory = described_class.inventory_for(organization.id)
        expect(inventory).to eq(EventTypes::Inventory.new(
          organization_id: organization.id,
          storage_locations: {
            storage_location1.id => EventTypes::EventStorageLocation.new(
              id: storage_location1.id,
              items: {
                item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 50, storage_location_id: storage_location1.id),
                item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 30, storage_location_id: storage_location1.id)
              }
            )
          }
        ))

        travel 1.minute
        # correction event - should ruin the snapshot since it's updating a previous event
        donation.line_items = [build(:line_item, quantity: 40, item: item1, itemizable: donation)]
        event = DonationEvent.publish(donation)
        event.update!(event_time: donation.created_at)
      end

      inventory = described_class.inventory_for(organization.id)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 40, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 0, storage_location_id: storage_location1.id)
            }
          )
        }
      ))
    end

    it "should handle multiple UpdateExisting events" do
      TestInventory.create_inventory(organization,
        {
          storage_location1.id => {
            item1.id => 70,
            item2.id => 60,
            item3.id => 20
          }
        })
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 50, item: item1, itemizable: donation)
      donation.line_items << build(:line_item, quantity: 30, item: item2, itemizable: donation)
      donation.save!

      attributes = {line_items_attributes: {"0": {item_id: item1.id, quantity: 40}, "1": {item_id: item2.id, quantity: 25}}}
      ItemizableUpdateService.call(itemizable: donation, type: :increase, event_class: DonationEvent, params: attributes)

      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              # (orig donation) 50 - (new donation) 40 = 10; (orig inventory)70 - (diff)10 = 60
              # (orig donation) 30 - (new donation) 25 = 5; (orig inventory)60 - (diff)5 = 55
              # no change to item3 so still 20
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 60, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 55, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 20, storage_location_id: storage_location1.id)
            }
          )
        }
      ))

      attributes = {line_items_attributes: {"0": {item_id: item1.id, quantity: 35}, "1": {item_id: item2.id, quantity: 30}}}
      ItemizableUpdateService.call(itemizable: donation, type: :increase, event_class: DonationEvent, params: attributes)

      result = InventoryAggregate.inventory_for(organization.id)
      expect(result).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              # (orig donation) 50 - (new donation) 35 = 15; (orig inventory)70 - (diff)15 = 55
              # item2 back to original 60
              # no change to item3 so still 20
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 55, storage_location_id: storage_location1.id),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 60, storage_location_id: storage_location1.id),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 20, storage_location_id: storage_location1.id)
            }
          )
        }
      ))
    end
  end

  describe "validation" do
    context "current event is incorrect" do
      it "should raise a bare error" do
        next unless Event.read_events?(organization) # only relevant if flag is on

        donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
        donation.line_items << build(:line_item, quantity: 50, item: item1)
        DonationEvent.publish(donation)

        distribution = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
        distribution.line_items << build(:line_item, quantity: 100, item: item1, itemizable: distribution)
        expect { DistributionEvent.publish(distribution) }.to raise_error do |e|
          expect(e).to be_a(InventoryError)
          expect(e.event).to be_a(DistributionEvent)
          expect(e.message).to eq("Could not reduce quantity by 100 - current quantity is 50 for #{item1.name} in #{storage_location1.name}")
        end
      end
    end

    context "subsequent event is incorrect" do
      it "should handle negative quantities" do
        next unless Event.read_events?(organization) # only relevant if flag is on

        donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
        donation.line_items << build(:line_item, quantity: 100, item: item1, itemizable: donation)
        DonationEvent.publish(donation)
        distribution = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
        distribution.line_items << build(:line_item, quantity: 90, item: item1, itemizable: distribution)
        DistributionEvent.publish(distribution)
        donation.line_items.first.quantity = 20
        expect { DonationEvent.publish(donation) }.to raise_error(InventoryError)
      end

      it "should add the event to the message" do
        next unless Event.read_events?(organization) # only relevant if flag is on

        travel_to Time.zone.local(2023, 5, 5)
        donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
        donation.line_items << build(:line_item, quantity: 50, item: item1, itemizable: donation)
        DonationEvent.publish(donation)

        travel 1.minute

        distribution = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
        distribution.line_items << build(:line_item, quantity: 10, item: item1, itemizable: distribution)
        DistributionEvent.publish(distribution)

        travel 1.minute

        distribution2 = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
        distribution2.line_items << build(:line_item, quantity: 20, item: item1, itemizable: distribution2)
        DistributionEvent.publish(distribution2)

        travel 1.minute

        distribution.line_items.first.update!(quantity: 40)
        expect { DistributionEvent.publish(distribution) }.to raise_error do |e|
          expect(e).to be_a(InventoryError)
          expect(e.event).to be_a(DistributionEvent)
          expect(e.message).to eq("Could not reduce quantity by 30 - current quantity is 20 for #{item1.name} in #{storage_location1.name}")
        end
      end
    end
  end
end
