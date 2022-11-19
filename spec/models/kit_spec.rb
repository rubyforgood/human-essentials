# == Schema Information
#
# Table name: kits
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(TRUE)
#  name                :string           not null
#  value_in_cents      :integer          default(0)
#  visible_to_partners :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organization_id     :integer          not null
#
require 'rails_helper'

RSpec.describe Kit, type: :model do
  let(:kit) { build(:kit, name: "Test Kit") }

  context "Validations >" do
    it "requires a unique name" do
      organization = create :organization
      kit = create(:kit, organization: organization)
      expect(
        build(:kit, name: kit.name, organization: organization)
      ).not_to be_valid
    end

    it "is valid as built" do
      expect(kit).to be_valid
    end

    it "must belong to an organization" do
      kit.organization = nil
      expect(kit).not_to be_valid
    end

    it "requires a name" do
      kit.name = nil
      expect(kit).not_to be_valid
    end

    it "requires at least one item" do
      kit.line_items = []
      expect(kit).not_to be_valid
    end

    it "can't have negative value" do
      kit.value_in_cents = 5
      expect(kit).to be_valid
      kit.value_in_cents = -5
      expect(kit).not_to be_valid
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

  context "Value >" do
    describe ".value_per_itemizable" do
      it "calculates values from associated items" do
        kit.line_items = [
          create(:line_item, item: create(:item, value_in_cents: 100)),
          create(:line_item, item: create(:item, value_in_cents: 90))
        ]
        expect(kit.value_per_itemizable).to eq(190)
      end
    end

    it "converts dollars to cents" do
      kit.value_in_dollars = 5.50
      expect(kit.value_in_cents).to eq(550)
    end

    it "converts cents to dollars" do
      kit.value_in_cents = 550
      expect(kit.value_in_dollars).to eq(5.50)
    end
  end

  describe '#can_deactivate?' do
    context 'with inventory items' do
      it 'should return false' do
        kit = create(:kit, :with_item)
        create(:inventory_item, item: kit.item)
        expect(kit.reload.can_deactivate?).to eq(false)
      end
    end

    context 'without inventory items' do
      it 'should return true' do
        kit = create(:kit, :with_item)
        expect(kit.reload.can_deactivate?).to eq(true)
      end
    end
  end

  specify 'deactivate and reactivate' do
    kit = create(:kit, :with_item)
    expect(kit.active).to eq(true)
    expect(kit.item.active).to eq(true)
    kit.deactivate
    expect(kit.active).to eq(false)
    expect(kit.item.active).to eq(false)
    kit.reactivate
    expect(kit.active).to eq(true)
    expect(kit.item.active).to eq(true)
  end
end
