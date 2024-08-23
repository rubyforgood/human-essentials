# == Schema Information
#
# Table name: item_requests
#
#  id                     :bigint           not null, primary key
#  name                   :string
#  partner_key            :string
#  quantity               :string
#  request_unit           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  item_id                :integer
#  old_partner_request_id :integer
#  partner_request_id     :bigint
#

RSpec.describe Partners::ItemRequest, type: :model do
  let(:organization) { create(:organization) }
  describe 'associations' do
    it { should belong_to(:request).class_name('::Request').with_foreign_key(:partner_request_id) }
    it { should have_many(:child_item_requests).dependent(:destroy) }
    it { should have_many(:children).through(:child_item_requests) }
  end

  describe 'validations' do
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than_or_equal_to(1) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:partner_key) }

    it "should only be able to use item's request units" do
      create(:unit, organization: organization, name: 'pack')
      create(:unit, organization: organization, name: 'flat')
      item = create(:item, organization: organization)
      item_unit = create(:item_unit, name: 'pack', item: item)
      request = build(:request, organization: organization)

      item_request = build(:item_request, request_unit: "flat", request: request, item: item)

      expect(item_request.valid?).to eq(false)
      expect(item_request.errors.full_messages).to eq(["Request unit is not supported"])

      item_unit.update!(name: 'flat')
      item.reload
      expect(item_request.valid?).to eq(true)
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end


