RSpec.describe ItemizableUpdateService do
  let(:organization) { create(:organization) }
  let(:storage_location) { create(:storage_location, organization: organization, item_count: 0) }
  let(:new_storage_location) { create(:storage_location, organization: organization, item_count: 0) }
  let(:item1) { create(:item, organization: organization, name: "My Item 1") }
  let(:item2) { create(:item, organization: organization, name: "My Item 2") }
  let(:item3) { create(:item, organization: organization, name: "My Item 3") }
  before(:each) do
    TestInventory.create_inventory(storage_location.organization, {
      storage_location.id => {
        item1.id => 10,
        item2.id => 10
      },
      new_storage_location.id => {
        item1.id => 10,
        item2.id => 10
      }
    })
  end

  around(:each) do |ex|
    freeze_time do
      ex.run
    end
  end

  describe "increases" do
    let(:itemizable) do
      line_items = [
        create(:line_item, item_id: item1.id, quantity: 5),
        create(:line_item, item_id: item2.id, quantity: 5)
      ]
      create(:donation,
        organization: organization,
        storage_location: storage_location,
        line_items: line_items,
        issued_at: 1.day.ago)
    end

    let(:attributes) do
      {
        issued_at: 2.days.ago,
        line_items_attributes: {"0": {item_id: item1.id, quantity: 2}, "1": {item_id: item2.id, quantity: 2}}
      }
    end

    subject do
      described_class.call(itemizable: itemizable,
        params: attributes,
        type: :increase,
        event_class: DonationEvent)
    end

    it "should update quantity in same storage location" do
      expect(storage_location.size).to eq(20)
      expect(new_storage_location.size).to eq(20)
      subject
      expect(itemizable.reload.line_items.count).to eq(2)
      expect(itemizable.line_items.sum(&:quantity)).to eq(4)
      expect(storage_location.size).to eq(14)
      expect(new_storage_location.size).to eq(20)
      expect(itemizable.issued_at).to eq(2.days.ago)
      expect(UpdateExistingEvent.count).to eq(1)
    end

    context "when storage location changes" do
      context "when there is no intervening audit" do
        it "should update quantity in different locations" do
          attributes[:storage_location_id] = new_storage_location.id
          subject
          expect(itemizable.reload.line_items.count).to eq(2)
          expect(itemizable.line_items.sum(&:quantity)).to eq(4)
          expect(storage_location.size).to eq(10)
          expect(new_storage_location.size).to eq(24)
        end
      end

      context "when there is an intervening audit on one of the items involved" do
        it "raises an error" do
          msg = "Cannot change the storage location because there has been an intervening audit of some items. " \
                "If you need to change the storage location, please delete this donation and create a new donation with the new storage location."
          create(:audit, :with_items, item: itemizable.items.first, organization: organization, storage_location: storage_location, status: "finalized")
          attributes[:storage_location_id] = new_storage_location.id
          expect { subject }.to raise_error(msg)
        end
      end
    end

    it "should raise an error if any item is inactive" do
      item1.update!(active: false)
      msg = "Update failed: The following items are currently inactive: My Item 1. Please reactivate them before continuing."
      expect { subject }.to raise_error(msg)
    end
  end

  describe "decreases" do
    let(:itemizable) do
      line_items = [
        create(:line_item, item_id: item1.id, quantity: 5),
        create(:line_item, item_id: item2.id, quantity: 5)
      ]
      create(:distribution,
        organization: organization,
        storage_location: storage_location,
        line_items: line_items,
        issued_at: 1.day.ago)
    end

    let(:attributes) do
      {
        issued_at: 2.days.ago,
        line_items_attributes: {"0": {item_id: item1.id, quantity: 2}, "1": {item_id: item2.id, quantity: 2}}
      }
    end

    subject do
      described_class.call(itemizable: itemizable, params: attributes, type: :decrease)
    end

    it "should update quantity in same storage location" do
      expect(storage_location.size).to eq(20)
      expect(new_storage_location.size).to eq(20)
      subject
      expect(itemizable.reload.line_items.count).to eq(2)
      expect(itemizable.line_items.sum(&:quantity)).to eq(4)
      expect(storage_location.size).to eq(26)
      expect(new_storage_location.size).to eq(20)
      expect(itemizable.issued_at).to eq(2.days.ago)
    end

    context "when storage location changes" do
      context "when there is no intervening audit" do
        it "should update quantity in different locations" do
          attributes[:storage_location_id] = new_storage_location.id
          subject
          expect(itemizable.reload.line_items.count).to eq(2)
          expect(itemizable.line_items.sum(&:quantity)).to eq(4)
          expect(storage_location.size).to eq(30)
          expect(new_storage_location.size).to eq(16)
        end
      end

      context "when there is an intervening audit on one of the items involved" do
        it "raises an error" do
          msg = "Cannot change the storage location because there has been an intervening audit of some items. " \
                "If you need to change the storage location, please reclaim this distribution and create a new distribution from the new storage location."
          create(:audit, :with_items, item: itemizable.items.first, organization: organization, storage_location: storage_location, status: "finalized")
          attributes[:storage_location_id] = new_storage_location.id
          expect { subject }.to raise_error(msg)
        end
      end
    end

    it "should raise an error if any item is inactive" do
      item1.update!(active: false)
      msg = "Update failed: The following items are currently inactive: My Item 1. Please reactivate them before continuing."
      expect { subject }.to raise_error(msg)
    end
  end

  describe "events" do
    before(:each) do
      allow(Event).to receive(:read_events?).and_return(true)
    end
    describe "with donations" do
      let(:itemizable) do
        line_items = [
          create(:line_item, item_id: item1.id, quantity: 10),
          create(:line_item, item_id: item2.id, quantity: 10)
        ]
        create(:donation,
          organization: organization,
          storage_location: storage_location,
          line_items: line_items,
          issued_at: 1.day.ago)
      end
      before(:each) do
        allow(Event).to receive(:read_events?).and_return(true)
      end
      let(:attributes) do
        {
          issued_at: 2.days.ago,
          line_items_attributes: {"0": {item_id: item1.id, quantity: 5}, "1": {item_id: item3.id, quantity: 50}}
        }
      end
      it "should send an itemizable event if it already exists" do
        DonationEvent.publish(itemizable)
        expect(DonationEvent.count).to eq(1)
        expect(View::Inventory.total_inventory(organization.id)).to eq(60)

        described_class.call(itemizable: itemizable, params: attributes, type: :increase, event_class: DonationEvent)

        expect(DonationEvent.count).to eq(2)
        expect(View::Inventory.total_inventory(organization.id)).to eq(95)
      end

      it "should send an update event if it does not exist" do
        expect(DonationEvent.count).to eq(0)
        expect(View::Inventory.total_inventory(organization.id)).to eq(40)

        described_class.call(itemizable: itemizable, params: attributes, type: :increase, event_class: DonationEvent)

        expect(DonationEvent.count).to eq(0)
        expect(UpdateExistingEvent.count).to eq(1)
        expect(View::Inventory.total_inventory(organization.id)).to eq(75) # 40 - 5 (item1) - 10 (item2) + 50 (item3)
      end
    end
    describe "with distributions" do
      before(:each) do
        TestInventory.create_inventory(storage_location.organization, {
          storage_location.id => {
            item3.id => 10
          }
        })
      end
      let(:itemizable) do
        line_items = [
          create(:line_item, item_id: item1.id, quantity: 5),
          create(:line_item, item_id: item2.id, quantity: 5)
        ]
        create(:distribution,
          organization: organization,
          storage_location: storage_location,
          line_items: line_items,
          issued_at: 1.day.ago)
      end
      let(:attributes) do
        {
          issued_at: 2.days.ago,
          line_items_attributes: {"0": {item_id: item1.id, quantity: 2}, "1": {item_id: item3.id, quantity: 6}}
        }
      end
      it "should send an itemizable event if it already exists" do
        DistributionEvent.publish(itemizable)
        expect(DistributionEvent.count).to eq(1)
        expect(View::Inventory.total_inventory(organization.id)).to eq(40)

        described_class.call(itemizable: itemizable, params: attributes, type: :decrease, event_class: DistributionEvent)

        expect(DistributionEvent.count).to eq(2)
        expect(View::Inventory.total_inventory(organization.id)).to eq(42)
      end

      it "should send an update event if it does not exist" do
        expect(DistributionEvent.count).to eq(0)
        expect(View::Inventory.total_inventory(organization.id)).to eq(50)

        described_class.call(itemizable: itemizable, params: attributes, type: :decrease, event_class: DistributionEvent)

        expect(DistributionEvent.count).to eq(0)
        expect(UpdateExistingEvent.count).to eq(1)
        expect(View::Inventory.total_inventory(organization.id)).to eq(52) # 50 + 3 (item1) + 5 (item2) +- 6 (item3)
      end
    end
  end
end
