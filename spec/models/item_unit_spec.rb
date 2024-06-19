# == Schema Information
#
# Table name: item_units
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  item_id    :bigint
#
RSpec.describe ItemUnit, type: :model do
  context "Validations >" do
    let(:organization) { create(:organization) }
    let(:item) { create(:item, organization: organization) }
    it "should only be valid if the organization has a corresponding unit" do
      item_unit = build(:item_unit, item: item, name: "pack")
      expect(item_unit.valid?).to eq(false)
      expect(item_unit.errors.full_messages).to eq(["Name is not supported by the organization"])

      create(:unit, organization: organization, name: "pack")
      organization.reload
      expect(item_unit.valid?).to eq(true)
    end
  end
end
