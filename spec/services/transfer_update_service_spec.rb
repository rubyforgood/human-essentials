require 'spec_helper'
require_relative '../support/env_helper'

RSpec.describe TransferUpdateService, type: :service do
  describe '#call' do
    subject { described_class.new(transfer_id: transfer_id, update_params: update_params).call }
    let(:transfer_id) { transfer.id }
    let(:transfer) { create(:transfer, organization: organization) }
    let(:organization) { create(:organization) }
    let(:update_params) do
      {
        from_id: updated_from_id,
        to_id: updated_to_id,
        comment: 'some comment',
        line_items_attributes: line_item_attrs
      }
    end
    let(:updated_from_id) { create(:storage_location).id }
    let(:updated_to_id) { create(:storage_location).id }
    let(:line_item_attrs) { {} }

    let(:fake_from) { double(transfer.from, increase_inventory: -> {}, decrease_inventory: ->{} ) }
    let(:fake_to) { double(transfer.to, increase_inventory: -> {}, decrease_inventory: ->{} ) }

    before do
      allow(Transfer).to receive(:find).with(transfer_id).and_return(transfer)
      allow(transfer).to receive(:from).and_return(fake_from)
      allow(transfer).to receive(:to).and_return(fake_to)
    end

    context 'when there are no issues' do
      context 'and the `to` of the transfer has changed' do
        let(:updated_from_id) { transfer.from_id }
        let(:updated_to_id) { create(:storage_location, organization: organization).id }

        it 'should return a OpenStruct with success? true' do
          expect(subject).to be_a_kind_of(OpenStruct)
          expect(subject.success?).to eq(true)
        end
      end
    end

    context 'when an issue occurs in transaction' do
      context 'because the transfer_id does not match any Transfer' do
        before do
          allow(Transfer).to receive(:find).with(transfer_id).and_raise(ActiveRecord::RecordNotFound)
        end

        it 'should return a OpenStruct with an ActiveRecord::RecordNotFound error' do
          expect(subject).to be_a_kind_of(OpenStruct)
          expect(subject.success?).to eq(false)
          expect(subject.error).to be_a_kind_of(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
end
