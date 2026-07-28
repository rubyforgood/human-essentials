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

  describe '#quantity_with_units' do
    context 'when enable_packs is enabled' do
      context 'when there is a request unit' do
        it 'returns the quantity with the request unit' do
          Flipper.enable(:enable_packs)

          item = create(:item, organization: organization)
          create(:item_unit, item:, name: 'flat')
          request = create(:request, organization: organization)
          item_request = create(:item_request, request:, item: item, request_unit: 'flat', name: "Item 1", quantity: 10)

          expect(item_request.quantity_with_units).to eq('10 flats')
        end
      end

      context 'when there is no request unit' do
        it 'returns only the quantity' do
          Flipper.enable(:enable_packs)

          item = create(:item, organization: organization)
          create(:item_unit, item:, name: 'flat')
          request = create(:request, organization: organization)
          item_request = create(:item_request, request:, item: item, name: 'Item 1', quantity: 10)

          expect(item_request.quantity_with_units).to eq('10')
        end
      end
    end

    context 'when enable_packs is disabled' do
      context 'when there is a request unit' do
        it 'returns only the quantity' do
          item = create(:item, organization: organization)
          create(:item_unit, item:, name: 'flat')
          request = create(:request, organization: organization)
          item_request = create(:item_request, request:, item: item, request_unit: 'flat', name: "Item 1", quantity: 10)

          expect(item_request.quantity_with_units).to eq('10')
        end
      end

      context 'when there is no request unit' do
        it 'returns only the quantity' do
          item = create(:item, organization: organization)
          create(:item_unit, item:, name: 'flat')
          request = create(:request, organization: organization)
          item_request = create(:item_request, request:, item: item, name: "Item 1", quantity: 10)

          expect(item_request.quantity_with_units).to eq("10")
        end
      end
    end
  end

  describe '#name_with_unit' do
    context 'when enable_packs is enabled' do
      context 'when there is a request unit' do
        it 'returns the item name with the request unit' do
          Flipper.enable(:enable_packs)

          item = create(:item, organization: organization, name: 'Item name')
          create(:item_unit, item:, name: 'flat')
          request = create(:request, organization: organization)
          item_request = create(:item_request, request:, item: item, request_unit: 'flat', name: "Item 1", quantity: 10)

          expect(item_request.name_with_unit).to eq('Item name - flats')
        end
      end

      context 'when there is no request unit' do
        it 'returns only the item name' do
          Flipper.enable(:enable_packs)

          item = create(:item, organization: organization, name: 'Item name')
          create(:item_unit, item:, name: 'flat')
          request = create(:request, organization: organization)
          item_request = create(:item_request, request:, item: item, name: 'Item 1', quantity: 10)

          expect(item_request.name_with_unit).to eq('Item name')
        end
      end
    end

    context 'when enable_packs is disabled' do
      context 'when there is a request unit' do
        it 'returns only the item_name' do
          item = create(:item, organization: organization, name: 'Item name')
          create(:item_unit, item:, name: 'flat')
          request = create(:request, organization: organization)
          item_request = create(:item_request, request:, item: item, request_unit: 'flat', name: "Item 1", quantity: 10)

          expect(item_request.name_with_unit).to eq('Item name')
        end
      end

      context 'when there is no request unit' do
        it 'returns only the item_name' do
          item = create(:item, organization: organization, name: 'Item name')
          create(:item_unit, item:, name: 'flat')
          request = create(:request, organization: organization)
          item_request = create(:item_request, request:, item: item, name: 'Item 1', quantity: 10)

          expect(item_request.name_with_unit).to eq('Item name')
        end
      end
    end
  end
end


