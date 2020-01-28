require 'spec_helper'
require_relative '../support/env_helper'

RSpec.describe TransferUpdateService, type: :service do
  describe '#call' do
    subject { described_class.new(transfer_id: transfer_id, update_params: update_params).call }
    let(:transfer_id) { transfer.id }
    let(:transfer) { create(:transfer, organization: organization) }
    let(:organization) { create(:organization) }
    let(:update_params) { { fake: 'fake-param' } }

    let(:fake_old_transfer) { double(transfer, from: fake_old_from, to: fake_old_to) }
    let(:fake_old_from) { instance_double(StorageLocation, increase_inventory: -> {}, decrease_inventory: -> {}) }
    let(:fake_old_to) { instance_double(StorageLocation, increase_inventory: -> {}, decrease_inventory: -> {}) }

    let(:fake_updated_transfer) { double(transfer, from: fake_updated_from, to: fake_updated_to, save!: -> {}) }
    let(:fake_updated_from) { instance_double(StorageLocation, increase_inventory: -> {}, decrease_inventory: -> {}) }
    let(:fake_updated_to) { instance_double(StorageLocation, increase_inventory: -> {}, decrease_inventory: -> {}) }

    before do
      allow(Transfer).to receive(:find).with(transfer_id).and_return(transfer)
      allow(transfer).to receive(:dup).and_return(fake_old_transfer)
      allow(transfer).to receive(:tap).and_return(fake_updated_transfer)
    end

    context 'when there are no issues' do
      context 'and the `from` of the transfer has changed' do
        before do
          # Configure the old and updated fake to contain
          # the same `to_id` and `line_items` (via to_a). But
          # change the `from_id` to trigger expected
          # logic pathway.
          allow(fake_old_transfer).to receive(:from_id).and_return(3)
          allow(fake_updated_transfer).to receive(:from_id).and_return(4)
          allow(fake_old_transfer).to receive(:to_id).and_return(3)
          allow(fake_updated_transfer).to receive(:to_id).and_return(3)
          allow(fake_old_transfer).to receive(:to_a).and_return([])
          allow(fake_updated_transfer).to receive(:to_a).and_return([])
        end

        it 'should return a OpenStruct with success? true' do
          expect(subject).to be_a_kind_of(OpenStruct)
          expect(subject.success?).to eq(true)
        end

        it 'should undo the old inventory changes and apply the updated inventory changes' do
          subject

          expect(fake_old_from).to have_received(:increase_inventory)
          expect(fake_old_to).to have_received(:decrease_inventory)

          expect(fake_updated_to).to have_received(:decrease_inventory)
          expect(fake_updated_from).to have_received(:increase_inventory)

          expect(fake_updated_transfer).to have_received(:save!)
        end
      end

      context 'and the `to` of the transfer has changed' do
        before do
          allow(fake_old_transfer).to receive(:from_id).and_return(3)
          allow(fake_updated_transfer).to receive(:from_id).and_return(3)
          allow(fake_old_transfer).to receive(:to_id).and_return(3)
          allow(fake_updated_transfer).to receive(:to_id).and_return(4)
          allow(fake_old_transfer).to receive(:to_a).and_return([])
          allow(fake_updated_transfer).to receive(:to_a).and_return([])
        end

        it 'should return a OpenStruct with success? true' do
          expect(subject).to be_a_kind_of(OpenStruct)
          expect(subject.success?).to eq(true)
        end

        it 'should undo the old inventory changes and apply the updated inventory changes' do
          subject

          expect(fake_old_from).to have_received(:increase_inventory)
          expect(fake_old_to).to have_received(:decrease_inventory)

          expect(fake_updated_to).to have_received(:decrease_inventory)
          expect(fake_updated_from).to have_received(:increase_inventory)

          expect(fake_updated_transfer).to have_received(:save!)
        end
      end

      context 'and the line_items (via to_a) have changed of the transfer has changed' do
        before do
          allow(fake_old_transfer).to receive(:from_id).and_return(3)
          allow(fake_updated_transfer).to receive(:from_id).and_return(3)
          allow(fake_old_transfer).to receive(:to_id).and_return(3)
          allow(fake_updated_transfer).to receive(:to_id).and_return(3)
          allow(fake_old_transfer).to receive(:to_a).and_return([])
          allow(fake_updated_transfer).to receive(:to_a).and_return(['different'])
        end

        it 'should return a OpenStruct with success? true' do
          expect(subject).to be_a_kind_of(OpenStruct)
          expect(subject.success?).to eq(true)
        end

        it 'should undo the old inventory changes and apply the updated inventory changes' do
          subject

          expect(fake_old_from).to have_received(:increase_inventory)
          expect(fake_old_to).to have_received(:decrease_inventory)

          expect(fake_updated_to).to have_received(:decrease_inventory)
          expect(fake_updated_from).to have_received(:increase_inventory)

          expect(fake_updated_transfer).to have_received(:save!)
        end
      end

      context 'and nothing related to the storage locations or line items have changed' do
        before do
          allow(fake_old_transfer).to receive(:from_id).and_return(3)
          allow(fake_updated_transfer).to receive(:from_id).and_return(3)
          allow(fake_old_transfer).to receive(:to_id).and_return(3)
          allow(fake_updated_transfer).to receive(:to_id).and_return(3)
          allow(fake_old_transfer).to receive(:to_a).and_return([])
          allow(fake_updated_transfer).to receive(:to_a).and_return([])
        end

        it 'should return a OpenStruct with success? true' do
          expect(subject).to be_a_kind_of(OpenStruct)
          expect(subject.success?).to eq(true)
        end

        it 'should not undo the old inventory changes and apply the updated inventory changes' do
          subject

          expect(fake_old_from).not_to have_received(:increase_inventory)
          expect(fake_old_to).not_to have_received(:decrease_inventory)

          expect(fake_updated_to).not_to have_received(:decrease_inventory)
          expect(fake_updated_from).not_to have_received(:increase_inventory)

          expect(fake_updated_transfer).to have_received(:save!)
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

      context 'because changing the inventory count raised an error' do
        let(:fake_raised_error_msg) { 'fake-error' }
        before do
          # Trigger the inventory count by making the `from_id`
          # change via the update.
          allow(fake_old_transfer).to receive(:from_id).and_return(3)
          allow(fake_updated_transfer).to receive(:from_id).and_return(4)
          allow(fake_old_from).to receive(:increase_inventory).and_raise(Errors::InsufficientAllotment.new(fake_raised_error_msg))
        end

        it 'should return a OpenStruct with an Errors::InsufficientAllotment error' do
          expect(subject).to be_a_kind_of(OpenStruct)
          expect(subject.success?).to eq(false)
          expect(subject.error).to be_a_kind_of(Errors::InsufficientAllotment)
        end

      end
    end
  end
end
