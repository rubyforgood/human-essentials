require 'rails_helper'

describe PartnerFetchRequestableItemsService do
  describe '#call' do
    subject { described_class.new(partner_id: partner.id).call }
    let(:partner) { create(:partner, organization: organization) }
    let!(:organization) { create(:organization, skip_items: true, items: org_items) }
    let(:org_items) { [] }
    let(:items_list) {
      [
        build(:item, active: true, visible_to_partners: true),
        build(:item, active: false, visible_to_partners: true),
        build(:item, active: true, visible_to_partners: false),
        build(:item, active: false, visible_to_partners: false)
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
          expected_items = [[items_list[0].name, items_list[0].id]]
          expect(subject).to eq(expected_items)
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
          expected_items = [[items_list[0].name, items_list[0].id]]
          expect(subject).to eq(expected_items)
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
