RSpec.describe ItemizableUpdateService, skip_seed: true do
  let(:organization) { create(:organization, skip_items: true) }
  let(:storage_location) { create(:storage_location, organization: organization, item_count: 0) }
  let(:new_storage_location) { create(:storage_location, organization: organization, item_count: 0) }
  let(:item1) { create(:item, organization: organization, name: "My Item 1") }
  let(:item2) { create(:item, organization: organization, name: "My Item 2") }
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
      expect(DonationEvent.count).to eq(1)
    end

    it "should update quantity in different locations" do
      attributes[:storage_location_id] = new_storage_location.id
      subject
      expect(itemizable.reload.line_items.count).to eq(2)
      expect(itemizable.line_items.sum(&:quantity)).to eq(4)
      expect(storage_location.size).to eq(10)
      expect(new_storage_location.size).to eq(24)
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

    it "should update quantity in different locations" do
      attributes[:storage_location_id] = new_storage_location.id
      subject
      expect(itemizable.reload.line_items.count).to eq(2)
      expect(itemizable.line_items.sum(&:quantity)).to eq(4)
      expect(storage_location.size).to eq(30)
      expect(new_storage_location.size).to eq(16)
    end

    it "should raise an error if any item is inactive" do
      item1.update!(active: false)
      msg = "Update failed: The following items are currently inactive: My Item 1. Please reactivate them before continuing."
      expect { subject }.to raise_error(msg)
    end
  end
end
