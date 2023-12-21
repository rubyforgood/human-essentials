RSpec.describe InventoryAggregate do
  let(:organization) { FactoryBot.create(:organization) }
  let(:storage_location1) { FactoryBot.create(:storage_location, organization: organization) }
  let(:storage_location2) { FactoryBot.create(:storage_location, organization: organization) }
  let(:item1) { FactoryBot.create(:item, organization: organization) }
  let(:item2) { FactoryBot.create(:item, organization: organization) }
  let(:item3) { FactoryBot.create(:item, organization: organization) }

  describe "discrepancy", skip_transaction: true do
    let(:donation) { create(:donation, organization: organization) }

    before(:each) do
      allow(InventoryAggregate).to receive(:inventory_for).and_return([])
      allow(EventDiffer).to receive(:check_difference).and_return([{foo: "bar"}, {baz: "spam"}])
    end

    it "should save a discrepancy" do
      DonationEvent.publish(donation)
      expect(InventoryDiscrepancy.count).to eq(1)
      disc = InventoryDiscrepancy.last
      expect(disc.event).to eq(DonationEvent.last)
      expect(disc.diff).to eq([{"foo" => "bar"}, {"baz" => "spam"}])
      expect(disc.organization).to eq(organization)
    end
  end

  describe "individual events" do
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
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      )
    end

    it "should process a donation event" do
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 50, item: item1)
      donation.line_items << build(:line_item, quantity: 30, item: item2)
      DonationEvent.publish(donation)

      # 30 + 50 = 80, 10 + 30 = 40
      described_class.handle(DonationEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 80),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 40),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      ))
    end

    it "should process a distribution event" do
      dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
      dist.line_items << build(:line_item, quantity: 20, item: item1)
      dist.line_items << build(:line_item, quantity: 5, item: item2)
      DistributionEvent.publish(dist)

      # 30 - 20 = 10, 10 - 5 = 5
      described_class.handle(DistributionEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      ))
    end

    it "should process a donation event after a new storage location is created" do
      new_loc = FactoryBot.create(:storage_location, organization: organization)
      donation = FactoryBot.create(:donation, organization: organization, storage_location: new_loc)
      donation.line_items << build(:line_item, quantity: 20, item: item1)
      donation.line_items << build(:line_item, quantity: 5, item: item2)
      DonationEvent.publish(donation)

      # 30 - 20 = 10, 10 - 5 = 5
      described_class.handle(DonationEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 30),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          ),
          new_loc.id => EventTypes::EventStorageLocation.new(
            id: new_loc.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 20),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5)
            }
          )
        }
      ))
    end

    it "should process a donation destroyed event" do
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 20, item: item1)
      donation.line_items << build(:line_item, quantity: 5, item: item2)
      DonationDestroyEvent.publish(donation)

      # 30 - 20 = 10, 10 - 5 = 5
      described_class.handle(DonationDestroyEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      ))
    end

    it "should process a purchase destroyed event" do
      purchase = FactoryBot.create(:purchase, organization: organization, storage_location: storage_location1)
      purchase.line_items << build(:line_item, quantity: 20, item: item1)
      purchase.line_items << build(:line_item, quantity: 5, item: item2)
      PurchaseDestroyEvent.publish(purchase)

      # 30 - 20 = 10, 10 - 5 = 5
      described_class.handle(PurchaseDestroyEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      ))
    end

    it "should process an adjustment event" do
      adjustment = FactoryBot.create(:adjustment, organization: organization, storage_location: storage_location1)
      adjustment.line_items << build(:line_item, quantity: 20, item: item1)
      adjustment.line_items << build(:line_item, quantity: -5, item: item2)
      AdjustmentEvent.publish(adjustment)

      # 30 + 20 = 50, 10 - 5 = 5
      described_class.handle(AdjustmentEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 50),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      ))
    end

    it "should process a purchase event" do
      purchase = FactoryBot.create(:purchase, organization: organization, storage_location: storage_location1)
      purchase.line_items << build(:line_item, quantity: 50, item: item1)
      purchase.line_items << build(:line_item, quantity: 30, item: item2)
      PurchaseEvent.publish(purchase)

      # 30 + 50 = 80, 10 + 30 = 40
      described_class.handle(PurchaseEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 80),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 40),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      ))
    end

    it "should process a distribution destroyed event" do
      dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
      dist.line_items << build(:line_item, quantity: 50, item: item1)
      dist.line_items << build(:line_item, quantity: 30, item: item2)
      DistributionDestroyEvent.publish(dist)

      # 30 + 50 = 80, 10 + 30 = 40
      described_class.handle(DistributionDestroyEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 80),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 40),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      ))
    end

    it "should process a transfer event" do
      transfer = FactoryBot.create(:transfer, organization: organization, from: storage_location1, to: storage_location2)
      transfer.line_items << build(:line_item, quantity: 20, item: item1)
      transfer.line_items << build(:line_item, quantity: 5, item: item2)
      TransferEvent.publish(transfer)

      # 30 - 20 = 10, 10 - 5 = 5
      # 0 + 20 = 20, 10 + 5 = 15
      described_class.handle(TransferEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 20),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 15),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      ))
    end

    it "should process a transfer destroy event" do
      transfer = FactoryBot.create(:transfer, organization: organization, from: storage_location2, to: storage_location1)
      transfer.line_items << build(:line_item, quantity: 20, item: item1)
      transfer.line_items << build(:line_item, quantity: 5, item: item2)
      TransferDestroyEvent.publish(transfer)

      # 30 - 20 = 10, 10 - 5 = 5
      # 0 + 20 = 20, 10 + 5 = 15
      described_class.handle(TransferDestroyEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 5),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 20),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 15),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      ))
    end

    it "should process an audit event" do
      audit = FactoryBot.create(:audit, organization: organization, storage_location: storage_location1)
      audit.line_items << build(:line_item, quantity: 20, item: item1)
      audit.line_items << build(:line_item, quantity: 10, item: item3)
      AuditEvent.publish(audit)

      described_class.handle(AuditEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 20),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 10)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      ))
    end

    it "should process a kit allocation event" do
      kit = FactoryBot.create(:kit, :with_item, organization: organization)
      kit.line_items = []
      kit.line_items << build(:line_item, quantity: 10, item: item1)
      kit.line_items << build(:line_item, quantity: 3, item: item2)
      KitAllocateEvent.publish(kit, storage_location1.id, 2)

      # 30 - (10*2) = 10, 10 - (3*2) = 4
      # 0 + 20 = 20, 10 + 5 = 15
      described_class.handle(KitAllocateEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 4),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40),
              kit.item.id => EventTypes::EventItem.new(item_id: kit.item.id, quantity: 2)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      ))
    end

    it "should process a kit deallocation event" do
      kit = FactoryBot.create(:kit, :with_item, organization: organization)
      kit.line_items = []
      kit.line_items << build(:line_item, quantity: 20, item: item1)
      kit.line_items << build(:line_item, quantity: 5, item: item2)
      inventory.move_item(item_id: kit.item.id, quantity: 3, to_location: storage_location1.id)
      KitDeallocateEvent.publish(kit, storage_location1, 2)

      # 30 + (20*2) = 70, 10 + (5*2) = 20
      described_class.handle(KitDeallocateEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 70),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 20),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 40),
              kit.item.id => EventTypes::EventItem.new(item_id: kit.item.id, quantity: 1)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 50)
            }
          )
        }
      ))
    end

    it "should process a snapshot event" do
      storage_location1.inventory_items.create!(quantity: 5, item_id: item1.id)
      storage_location1.inventory_items.create!(quantity: 10, item_id: item2.id)
      storage_location2.inventory_items.create!(quantity: 15, item_id: item2.id)
      storage_location2.inventory_items.create!(quantity: 20, item_id: item3.id)
      SnapshotEvent.publish(organization)

      described_class.handle(SnapshotEvent.last, inventory)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 5),
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 10)
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 15),
              item3.id => EventTypes::EventItem.new(item_id: item3.id, quantity: 20)
            }
          )
        }
      ))
    end
  end

  describe "multiple events" do
    it "should process multiple events" do
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
            }
          ),
          storage_location2.id => EventTypes::EventStorageLocation.new(
            id: storage_location2.id,
            items: {
              item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 25)
            }
          )
        }
      ))
    end

    it "should validate incorrect events" do
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 10, item: item1)
      DonationEvent.publish(donation)

      dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
      dist.line_items << build(:line_item, quantity: 20, item: item1)
      DistributionEvent.publish(dist)

      expect { described_class.inventory_for(organization.id, validate: true) }
        .to raise_error("Could not reduce quantity by 20 for item #{item1.id} in storage location #{storage_location1.id} - current quantity is 10")
    end

    it "should handle timing correctly" do
      donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
      donation.line_items << build(:line_item, quantity: 30, item: item1)
      DonationEvent.publish(donation)

      dist = FactoryBot.create(:distribution, organization: organization, storage_location: storage_location1)
      dist.line_items << build(:line_item, quantity: 10, item: item1)
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
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 10)
            }
          )
        }
      ))
    end

    it 'should ignore unusable snapshots' do
      freeze_time do
        donation = FactoryBot.create(:donation, organization: organization, storage_location: storage_location1)
        donation.line_items << build(:line_item, quantity: 50, item: item1)
        donation.line_items << build(:line_item, quantity: 30, item: item2)
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
                item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 50),
                item2.id => EventTypes::EventItem.new(item_id: item2.id, quantity: 30),
              }
            )
          }
        ))

        travel 1.minute
        # correction event - should ruin the snapshot since it's updating a previous event
        donation.line_items = [build(:line_item, quantity: 40, item: item1)]
        DonationEvent.publish(donation)
      end

      inventory = described_class.inventory_for(organization.id)
      expect(inventory).to eq(EventTypes::Inventory.new(
        organization_id: organization.id,
        storage_locations: {
          storage_location1.id => EventTypes::EventStorageLocation.new(
            id: storage_location1.id,
            items: {
              item1.id => EventTypes::EventItem.new(item_id: item1.id, quantity: 40)
            }
          )
        }
      ))
    end

  end
end
