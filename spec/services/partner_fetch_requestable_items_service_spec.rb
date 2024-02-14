require 'rails_helper'

describe PartnerFetchRequestableItemsService do
  describe '#call' do
    subject { described_class.new(partner_id: partner_id).call }
    let(:partner_id) { partner.id }
    let(:partner) { create(:partner, organization:) }
    let(:organization) { create(:organization, skip_items: true, items:) }
    let(:items) {
      [
        build(:item, active: true, visible_to_partners: true),
        build(:item, active: false, visible_to_partners: true),
        build(:item, active: true, visible_to_partners: false),
        build(:item, active: false, visible_to_partners: false)
      ]
    }
    let(:partner_items) {
      [
        build(:item, active: true, visible_to_partners: true),
        build(:item, active: false, visible_to_partners: true),
        build(:item, active: true, visible_to_partners: false),
        build(:item, active: false, visible_to_partners: false)
      ]
    }

    context 'when the partner id does not match any Partner' do
      let(:partner_id) { 0 }

      it 'raise an error indiciating the partner does not exist' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the partner is not in any partner group' do
      before do
        expect(partner.partner_group).to be_nil
      end

      it 'should return all active and visible items' do
        expected_items = [[items[0].name, items[0].id]]
        expect(subject).to eq(expected_items)
      end
    end

    context 'when the partner is in a partner group' do
      before do
        pg = create(:partner_group)
        item_category = create(:item_category, organization: organization)
        item_category.items << partner_items
        pg.item_categories << item_category
        partner.update(partner_group: pg)
      end

      it 'should return all active and visible items specified by the item associated with' do
        expected_items = [[partner_items[0].name, partner_items[0].id]]
        expect(subject).to eq(expected_items)
      end
    end
  end
end
