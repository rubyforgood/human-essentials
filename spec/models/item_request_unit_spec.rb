RSpec.describe ItemRequestUnit, type: :model do
  context "Validations >" do
    let(:organization) { create(:organization) }
    let(:item) { create(:item, organization: organization) }
    it 'should only be valid if the organization has a corresponding unit' do
      unit = build(:item_request_unit, item: item, name: 'pack')
      expect(unit.valid?).to eq(false)
      expect(unit.errors.full_messages).to eq(["Name is not supported by the organization"])

      create(:request_unit, organization: organization, name: 'pack')
      organization.reload
      expect(unit.valid?).to eq(true)
    end
  end
end
