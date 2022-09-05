RSpec.describe DistributionContentChangeService, type: :service do
  let(:line_item1) { { active: true, item_id: 32, name: "Adult Incontinence Pads", quantity: 382 } }
  let(:line_item2) { { active: true, item_id: 38, name: "Bed Pads (Disposable)", quantity: 36 } }
  let(:line_item3) { { active: true, item_id: 43, name: "Wipes (Adult)", quantity: 88 } }
  let(:line_item4) { { active: true, item_id: 30, name: "Cloth Inserts (For Cloth Diapers)", quantity: 101 } }

  describe "#any_change?" do
    subject { DistributionContentChangeService.new(old_line_items, new_line_items).call }

    context "when there are line items updated" do
      let(:old_line_items) { [line_item1, line_item2, line_item3] }
      let(:new_line_items) { [line_item1.clone, line_item2, line_item3.clone] }

      before do
        new_line_items[0][:quantity] = 30
        new_line_items[2][:quantity] = 50
      end

      it "returns true" do
        expect(subject.any_change?).to be_truthy
      end
    end

    context "when there are line items removed" do
      let(:old_line_items) { [line_item1, line_item2, line_item3, line_item4] }
      let(:new_line_items) { [line_item1, line_item2, line_item3] }

      it "returns true" do
        expect(subject.any_change?).to be_truthy
      end
    end

    context "when there are line items removed and updated" do
      let(:old_line_items) { [line_item1, line_item2, line_item3, line_item4] }
      let(:new_line_items) { [line_item1.clone, line_item2, line_item3] }

      before do
        new_line_items[0][:quantity] = 30
      end

      it "returns true" do
        expect(subject.any_change?).to be_truthy
      end
    end

    context "when there are no changes in the line items" do
      let(:old_line_items) { [line_item1, line_item2, line_item3, line_item4] }
      let(:new_line_items) { [line_item1, line_item2, line_item3, line_item4] }

      it "returns true" do
        expect(subject.any_change?).to be_falsy
      end
    end
  end

  describe "#changes" do
    subject { DistributionContentChangeService.new(old_line_items, new_line_items).call }

    context "when there are line items removed and updated" do
      let(:old_line_items) { [line_item1, line_item2, line_item3, line_item4] }
      let(:new_line_items) { [line_item1.clone, line_item2, line_item3] }

      before do
        new_line_items[0][:quantity] = 30
      end

      it "returns true" do
        expected_changes = {
          removed: [line_item4],
          updates: [
            {
              name: old_line_items[0][:name],
              new_quantity: new_line_items[0][:quantity],
              old_quantity: old_line_items[0][:quantity]
            }
          ]
        }
        expect(subject.changes).to eq expected_changes
      end
    end
  end
end
