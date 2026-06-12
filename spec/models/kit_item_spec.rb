# == Schema Information
#
# Table name: items
#
#  id                           :integer          not null, primary key
#  active                       :boolean          default(TRUE)
#  additional_info              :text
#  barcode_count                :integer
#  distribution_quantity        :integer
#  name                         :string
#  on_hand_minimum_quantity     :integer          default(0), not null
#  on_hand_recommended_quantity :integer
#  package_size                 :integer
#  partner_key                  :string
#  reporting_category           :string
#  type                         :string           default("ConcreteItem"), not null
#  value_in_cents               :integer          default(0)
#  visible_to_partners          :boolean          default(TRUE), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  item_category_id             :integer
#  kit_id                       :integer
#  organization_id              :integer
#

RSpec.describe KitItem, type: :model do
  let(:organization) { create(:organization) }

  let(:kit) { build(:kit_item, name: "Test Kit", organization: organization) }

  context "Validations >" do
    subject { build(:kit_item, organization: organization) }

    it { should validate_presence_of(:name) }
    it { should belong_to(:organization) }
    it { should validate_numericality_of(:value_in_cents).is_greater_than_or_equal_to(0) }

    it "requires a unique name" do
      subject.save
      expect(
        build(:kit_item, name: subject.name, organization: organization)
      ).not_to be_valid
    end

    it "ensures the associated line_items are invalid with a nil quantity" do
      kit.line_items << build(:line_item, quantity: nil)
      expect(kit).not_to be_valid
    end

    it "ensures the associated line_items are invalid with a zero quantity" do
      kit.line_items << build(:line_item, quantity: 0)
      expect(kit).not_to be_valid
    end

    it "ensures the associated line_items are valid with a one quantity" do
      kit.line_items = [build(:line_item, quantity: 1, item: create(:item, organization: organization))]
      expect(kit).to be_valid
    end
  end

  context "Filtering >" do
    it "can filter" do
      expect(subject.class).to respond_to :class_filter
    end

    it "->alphabetized retrieves items in alphabetical order" do
      a_name = "KitA"
      b_name = "KitB"
      c_name = "KitC"
      create(:kit_item, name: c_name, organization: organization)
      create(:kit_item, name: b_name, organization: organization)
      create(:kit_item, name: a_name, organization: organization)
      alphabetized_list = [a_name, b_name, c_name]

      expect(organization.kit_items.alphabetized.count).to eq(3)
      expect(organization.kit_items.alphabetized.map(&:name)).to eq(alphabetized_list)
    end

    it "->by_name filters by name" do
      create(:kit_item, name: "Newborn Kit", organization: organization)
      create(:kit_item, name: "Toddler Kit", organization: organization)

      expect(organization.kit_items.by_name("newborn").map(&:name)).to eq(["Newborn Kit"])
    end
  end

  context "Value >" do
    describe "#value_per_itemizable" do
      it "calculates values from associated items" do
        kit.line_items = [
          create(:line_item, quantity: 1, item: create(:item, value_in_cents: 100, organization: organization)),
          create(:line_item, quantity: 1, item: create(:item, value_in_cents: 90, organization: organization))
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

  describe "#can_deactivate_or_delete?" do
    let(:kit) { create_kit(organization: organization) }

    context "with inventory" do
      it "should return false" do
        storage_location = create(:storage_location, organization: organization)

        TestInventory.create_inventory(organization, {
          storage_location.id => {
            kit.id => 10
          }
        })
        expect(kit.reload.can_deactivate_or_delete?).to eq(false)
      end
    end

    context "without inventory items" do
      it "should return true" do
        expect(kit.reload.can_deactivate_or_delete?).to eq(true)
      end
    end
  end

  describe "#can_reactivate?" do
    let(:kit) { create_kit(organization: organization) }

    it "is true when all contained items are active" do
      expect(kit.can_reactivate?).to eq(true)
    end

    it "is false when a contained item is inactive" do
      kit.line_items.first.item.update!(active: false)
      expect(kit.reload.can_reactivate?).to eq(false)
    end
  end

  specify "deactivate and reactivate" do
    kit = create_kit(organization: organization)
    expect(kit.active).to eq(true)
    kit.deactivate!
    expect(kit.reload.active).to eq(false)
    kit.reactivate
    expect(kit.reload.active).to eq(true)
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
