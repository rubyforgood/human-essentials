# == Schema Information
#
# Table name: line_items
#
#  id              :bigint(8)        not null, primary key
#  quantity        :integer
#  item_id         :integer
#  itemizable_id   :integer
#  itemizable_type :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

RSpec.describe LineItem, type: :model do
  context "Validations >" do
    it "requires an item" do
      expect(build(:line_item, item: nil)).not_to be_valid
    end

    it "requires a quantity" do
      expect(build(:line_item, quantity: nil)).not_to be_valid
    end

    it "the quantity must be a valid integer and cannot be 0" do
      expect(build(:line_item, :purchase, quantity: "a")).not_to be_valid
      expect(build(:line_item, :purchase, quantity: "1.0")).not_to be_valid
      expect(build(:line_item, :purchase, quantity: 0)).to be_valid
      expect(build(:line_item, :purchase, quantity: 2**31)).not_to be_valid
      expect(build(:line_item, :purchase, quantity: -2**32)).not_to be_valid
      expect(build_stubbed(:line_item, :purchase, quantity: -1)).to be_valid
      expect(build_stubbed(:line_item, :purchase, quantity: 1)).to be_valid
    end
  end

  describe "package_count" do
    it "is equal to the quanity divided by the package_size" do
      item = create(:item, package_size: 10)
      line_item = create(:line_item, :purchase, quantity: 100, item_id: item.id)
      expect(line_item.package_count).to eq("10")
    end

    it "is nil if there is no package_size" do
      item = create(:item)
      line_item = create(:line_item, :purchase, quantity: 100, item_id: item.id)
      expect(line_item.package_count).to be_nil
    end
  end

  describe "Scopes >" do
    describe "->active" do
      let!(:active_item) { create(:item, :active) }
      let!(:inactive_item) { create(:item, :inactive) }

      before do
        create(:line_item, :purchase, item: active_item)
        create(:line_item, :purchase, item: inactive_item)
      end

      it "retrieves only those with active status" do
        expect(described_class.active.size).to eq(1)
      end
    end
  end
end
