# == Schema Information
#
# Table name: kits
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(TRUE)
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#
require 'rails_helper'

RSpec.describe Kit, type: :model do
  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:kit, organization: nil, name: "Test Kit")).not_to be_valid
      expect(build(:kit, name: "Test Kit")).to be_valid
    end

    it "requires a name" do
      expect(build(:kit, name: nil)).not_to be_valid
      expect(build(:kit, name: "Test Kit")).to be_valid
    end
  end

  context "Filtering >" do
    it "can filter" do
      expect(subject.class).to respond_to :class_filter
    end

    it "->alphabetized retrieves items in alphabetical order" do
      kit_c = create(:kit, name: "C")
      kit_b = create(:kit, name: "B")
      kit_a = create(:kit, name: "A")
      alphabetized_list = [kit_a.name, kit_b.name, kit_c.name]
      expect(Kit.alphabetized.count).to eq(3)
      expect(Kit.alphabetized.map(&:name)).to eq(alphabetized_list)
    end

    describe "->by_partner_key" do
      it "shows the kits for a particular item" do
        organization = create :organization
        c1 = create(:item, base_item: create(:base_item))
        c2 = create(:item, base_item: create(:base_item))
        create(:kit, organization: organization, line_items: [create(:line_item, item: c1)])
        create(:kit, organization: organization, line_items: [create(:line_item, item: c2)])
        expect(Kit.by_partner_key(c1.partner_key).size).to eq(1)
        expect(Kit.active.size).to be > 1
      end
    end
  end
end
