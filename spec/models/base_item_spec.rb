# == Schema Information
#
# Table name: base_items
#
#  id            :bigint           not null, primary key
#  barcode_count :integer
#  category      :string
#  item_count    :integer
#  name          :string
#  partner_key   :string
#  size          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require "rails_helper"

RSpec.describe BaseItem, type: :model do
  describe "Validations >" do
    it "is invalid without a name" do
      expect(build(:base_item, name: nil)).not_to be_valid
    end

    it "is invalid without a unique name" do
      f = create(:base_item)
      expect(build(:base_item, name: f.name)).not_to be_valid
    end

    it "is invalid without a partner key" do
      expect(build(:base_item, partner_key: nil)).not_to be_valid
    end

    it "is invalid without a uniqueness key" do
      f = create(:base_item)
      expect(build(:base_item, partner_key: f.partner_key)).not_to be_valid
    end
  end

  describe "Associations >" do
    it "keeps count of its associated items" do
      c = BaseItem.first
      expect { create_list(:item, 2, base_item: c) }.to change { c.item_count }.by(2)
    end
  end

  describe "Methods >" do
  end

  describe "Filtering >" do
    describe '->without_kit' do
      subject { BaseItem.without_kit }

      let!(:kit_base_item) { BaseItem.find_by(name: 'Kit') }
      it 'should not include the Kit BaseItem' do
        expect(subject).not_to include(kit_base_item)
      end
    end

    describe "->by_partner_key" do
      it "shows the Base Items by partner_key" do
        expect(BaseItem.by_partner_key(BaseItem.first.partner_key).size).to eq(1)
        expect(BaseItem.by_partner_key("random_string").size).to eq(0)
      end
    end
  end
end
