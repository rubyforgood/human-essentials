require 'rails_helper'

describe PartnerFetchRequestableItemsService do
  describe '#call' do
    subject { described_class.new(partner_id: partner_id).call }
    let(:partner_id) { partner.id }
    let(:partner) { create(:partner) }
    let(:organization) { partner.organization }

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
        expect(subject).to eq(organization.items.active.visible)
      end
    end

    context 'when the partner is in a partner group' do
      before do
        pg = create(:partner_group)
        pg.item_categories << create(:item_category, organization: organization)
        partner.update(partner_group: pg)
      end

      it 'should return all active and visible items specified by the item associated with' do
        expect(subject).to eq(partner.requestable_items.active.visible)
      end
    end
  end
end
