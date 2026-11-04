RSpec.describe EventTypes::EventStorageLocation do
  let(:item_id) { 1 }
  let(:starting_quantity) { 50 }
  let(:starting_reserved_quantity) { 20 }

  subject(:base_event) do
    described_class.new(
      id: 10,
      items: {
        item_id => EventTypes::EventItem.new(
          item_id: item_id, 
          storage_location_id: 10, 
          quantity: starting_quantity, 
          reserved_quantity: starting_reserved_quantity,
        )
      }
    )
  end

  def entry
    base_event.items[item_id]
  end

  describe "#adjust_reserved" do
    let(:delta) { 0 }
    subject { base_event.adjust_reserved(item_id, delta) }

    context "when it increases the reserved amount" do
      let(:delta) { 20 }

      it "changes the reserved quantity but not the available quantity" do
        expect {
          subject
        }.not_to change { entry.quantity }.from(starting_quantity)
        
        expect(entry.reserved_quantity).to eq(starting_reserved_quantity + delta)
      end  
    end
    
    context "when it decreases the reserved amount" do
      let(:delta) { -20 }

      it "changes the reserved quantity but not the available quantity" do
        expect {
          subject
        }.not_to change { entry.quantity }.from(starting_quantity)
        
        expect(entry.reserved_quantity).to eq(starting_reserved_quantity + delta)
      end
    end

    context "when it attempts to modify an item that does not yet exist" do
      let(:unknown_item_id) { 2 }

      before do
        expect { Item.find(unknown_item_id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      subject { base_event.adjust_reserved(2, 15) }

      pending "⚠️ What should happen here?" do
        # Possible avenues: raise an exception? set to 0? 
        # This is the behavior that Claude generated, but I don't think it's right.
        expect(subject.items[2].reserved_quantity).to eq(15)
        expect(subject.items[2].quantity).to eq(0)  
      end
    end
    
    context "when attempting to release more reserves than available" do
      let(:delta) { (starting_reserved_quantity + 10) * -1}

      before do
        expect(entry.reserved_quantity).to be < delta.abs
      end

      it "raises when a release would drive reserved negative" do
        expect { subject }.to raise_error(InventoryActionError)
        expect(entry.reserved_quantity).to eq(starting_reserved_quantity)
      end

      context "and the validation is turned off" do
        subject { base_event.adjust_reserved(item_id, delta, validate: false) }

        it "allows reserved to go negative when validation is off" do
          expect {
            subject
          }.to change { entry.reserved_quantity }.by(delta)
        end
      end
    end
  end

  describe "#add_inventory" do
    let(:delta) { 10 }
    subject { base_event.add_inventory(item_id, delta) }

    it "increase the quantity but not the reserved_quantity" do
      subject
      expect(entry.quantity).to eq(starting_quantity + delta)
      expect(entry.reserved_quantity).to eq(starting_reserved_quantity)
    end
  end

  describe "#reduce_inventory" do
    let(:delta) { 10 }
    subject { base_event.reduce_inventory(item_id, delta) }

    it "decreases the quantity but not the reserved_quantity" do
      subject
      expect(entry.quantity).to eq(starting_quantity - delta)
      expect(entry.reserved_quantity).to eq(starting_reserved_quantity)
    end

  end

  describe "#set_inventory" do
    let(:new_value) { 5 }
    subject { base_event.set_inventory(item_id, new_value) }

    it "changes the inventory but does not change the reserved quantity" do
      subject
      expect(entry.quantity).to eq(new_value)
      expect(entry.reserved_quantity).to eq(starting_reserved_quantity)
    end    
  end
end
