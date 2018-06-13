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

    it "the quantity must be an integer and cannot be 0" do
      expect(build(:line_item, quantity: "a")).not_to be_valid
      expect(build(:line_item, quantity: "1.0")).not_to be_valid
      expect(build(:line_item, quantity: 0)).not_to be_valid
      expect(build(:line_item, quantity: -1)).to be_valid
      expect(build(:line_item, quantity: 1)).to be_valid
    end
  end
end
