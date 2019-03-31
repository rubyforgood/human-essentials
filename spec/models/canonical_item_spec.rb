# == Schema Information
#
# Table name: canonical_items
#
#  id            :bigint(8)        not null, primary key
#  name          :string
#  category      :string
#  barcode_count :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  size          :string
#  item_count    :integer
#  partner_key   :string
#

require "rails_helper"

RSpec.describe CanonicalItem, type: :model do
  describe "Validations >" do
    it "is invalid without a name" do
      expect(build(:canonical_item, name: nil)).not_to be_valid
    end

    it "is invalid without a unique name" do
      f = create(:canonical_item)
      expect(build(:canonical_item, name: f.name)).not_to be_valid
    end

    it "is invalid without a partner key" do
      expect(build(:canonical_item, partner_key: nil)).not_to be_valid
    end

    it "is invalid without a uniqueness key" do
      f = create(:canonical_item)
      expect(build(:canonical_item, partner_key: f.partner_key)).not_to be_valid
    end
  end

  describe "Associations >" do
    it "keeps count of its associated items" do
      c = CanonicalItem.first
      expect { create_list(:item, 2, canonical_item: c) }.to change { c.item_count }.by(2)
    end
  end

  describe "Methods >" do
  end

  describe "Filtering >" do
    describe "->by_partner_key" do
      it "shows the Canonical Items by partner_key" do
        expect(CanonicalItem.by_partner_key(CanonicalItem.first.partner_key).size).to eq(1)
        expect(CanonicalItem.by_partner_key("random_string").size).to eq(0)
      end
    end
  end
end
