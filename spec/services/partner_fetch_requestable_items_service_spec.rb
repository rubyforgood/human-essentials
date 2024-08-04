RSpec.describe PartnerFetchRequestableItemsService do
  describe '#call' do
    subject { described_class.new(partner_id: partner.id).call }
    let!(:organization) { create(:organization, items: org_items) }
    let(:partner) { create(:partner, organization: organization) }
    let(:org_items) { [] }
    let(:items_list) {
      [
        build(:item, active: true, visible_to_partners: true, name: 'Item 1'),
        build(:item, active: false, visible_to_partners: true, name: 'Item 2'),
        build(:item, active: true, visible_to_partners: false, name: 'Item 3'),
        build(:item, active: false, visible_to_partners: false, name: 'Item 4')
      ]
    }

    it 'raises an error indiciating the partner does not exist with invalid id' do
      invalid_partner_id = 0
      expect do
        PartnerFetchRequestableItemsService.new(partner_id: invalid_partner_id).call
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when the partner is not in any partner group' do
      it { expect(partner.partner_group).to be_nil }

      context 'when the organization has no items' do
        let(:org_items) { [] }

        it 'should return no items' do
          expect(subject).to be_empty
        end
      end

      context 'when the organization has items' do
        let(:org_items) { items_list }

        it { expect(organization.items).to eq(items_list) }

        it 'should return only active and visible items' do
          got_items = subject.map { |i| i[0] }
          expect(got_items).to eq(["Item 1"])
        end
      end
    end

    context 'org with any amount of items' do
      let(:organization) { create(:organization) }

      context 'when the partner is in a partner group and has items' do
        before do
          pg = create(:partner_group)
          item_category = create(:item_category, organization: organization)
          item_category.items << items_list
          pg.item_categories << item_category
          partner.update(partner_group: pg)
        end

        it 'should return only active and visible items from partner' do
          got_items = subject.map { |i| i[0] }
          expect(got_items).to eq(["Item 1"])
        end
      end

      context 'when the partner is in a partner group and has no items' do
        before do
          pg = create(:partner_group)
          partner.update(partner_group: pg)
        end

        it 'should return only active and visible items from partner' do
          expect(subject).to be_empty
        end
      end
    end
  end
end
