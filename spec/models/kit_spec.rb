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

RSpec.describe Kit, type: :model do
  let(:organization) { create(:organization) }

  let(:kit) { build(:kit, name: "Test Kit") }

  context "Validations >" do
    subject { build(:kit, organization: organization) }

    it { should validate_presence_of(:name) }
    it { should belong_to(:organization) }
    it { should validate_numericality_of(:value_in_cents).is_greater_than_or_equal_to(0) }

    it "requires a unique name" do
      subject.save
      expect(
        build(:kit, name: subject.name, organization: organization)
      ).not_to be_valid
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
      create(:kit, name: c_name)
      create(:kit, name: b_name)
      create(:kit, name: a_name)
      alphabetized_list = [a_name, b_name, c_name]

      expect(Kit.alphabetized.count).to eq(3)
      expect(Kit.alphabetized.map(&:name)).to eq(alphabetized_list)
    end
  end

  context "Value >" do
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
    let(:kit) {
      kit_params = attributes_for(:kit)
      kit_params[:line_items_attributes] = [{item_id: create(:item).id, quantity: 1}]
      KitCreateService.new(organization_id: organization.id, kit_params: kit_params).call.kit
    }

    context 'with inventory' do
      it 'should return false' do
        storage_location = create(:storage_location, organization: organization)

        TestInventory.create_inventory(organization, {
          storage_location.id => {
            kit.item.id => 10
          }
        })
        expect(kit.reload.can_deactivate?(nil)).to eq(false)
      end
    end

    context 'without inventory items' do
      it 'should return true' do
        expect(kit.reload.can_deactivate?(nil)).to eq(true)
      end
    end
  end

  specify 'deactivate and reactivate' do
    params = FactoryBot.attributes_for(:kit)
    params[:line_items_attributes] = [
      {item_id: create(:item).id, quantity: 1}
    ]
    kit = KitCreateService.new(organization_id: organization.id, kit_params: params).call.kit
    expect(kit.active).to eq(true)
    expect(kit.item.active).to eq(true)
    kit.deactivate
    expect(kit.active).to eq(false)
    expect(kit.item.active).to eq(false)
    kit.reactivate
    expect(kit.active).to eq(true)
    expect(kit.item.active).to eq(true)
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
