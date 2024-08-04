RSpec.describe DistributionDestroyService do
  describe '#call' do
    subject { described_class.new(distribution_id).call }
    let(:distribution_id) { Faker::Number.number }

    context 'when the distribution_id matches no Distribution' do
      before do
        allow(Distribution).to receive(:find)
          .with(distribution_id)
          .and_raise(ActiveRecord::RecordNotFound)
      end

      it 'to not be a success' do
        result = subject.call
        expect(result).not_to be_success
      end
    end

    context 'when the distribution_id does match a Distribution' do
      let!(:distribution) { create(:distribution, organization: create(:organization)) }

      before do
        # Use this approach to so that I can force outcomes on the
        # instance of distribution that the service object is using.
        allow(Distribution).to receive(:find)
          .with(distribution_id)
          .and_return(distribution)
      end

      context 'and the operations succeed' do
        let(:fake_storage_location) { instance_double(StorageLocation) }
        let(:fake_items) do
          [
            {
              item_id: Faker::Number.number,
              item: Faker::Lorem.word,
              quantity_on_hand: Faker::Number.number,
              quantity_requested: Faker::Number.number
            }
          ]
        end
        before do
          allow(distribution).to receive(:storage_location).and_return(fake_storage_location)
          allow(distribution).to receive(:line_item_values).and_return(fake_items)
          allow(fake_storage_location).to receive(:increase_inventory)
        end

        it 'should destroy the Distribution' do
          expect { subject }.to change { Distribution.count }.by(-1)
            .and change { DistributionDestroyEvent.count }.by(1)
        end

        it 'should be successful' do
          result = subject
          expect(result).to be_success
        end

        it 'should increase the inventory of the storage location' do
          subject
          expect(fake_storage_location).to have_received(:increase_inventory).with(fake_items)
        end
      end

      context 'and the destroy! operation fails' do
        let(:fake_destroy_error) { 'booom' }

        before do
          allow(distribution).to receive(:destroy!).and_raise(
            StandardError.new(fake_destroy_error)
          )
        end

        it 'should not delete the Distribution' do
          expect { subject }.not_to change { Distribution.count }
        end

        it 'should not be successful and have the error message' do
          result = subject
          expect(result).not_to be_success
          expect(result.error).to be_instance_of(StandardError)
          expect(result.error.message).to eq(fake_destroy_error)
        end
      end

      context 'and the increase inventory operations fails' do
        let(:fake_storage_location) { instance_double(StorageLocation) }
        let(:fake_insufficient_allotment_error) do
          Errors::InsufficientAllotment.new(
            fake_error_message,
            fake_insufficient_items
          )
        end
        let(:fake_error_message) { Faker::Lorem.sentence }
        let(:fake_insufficient_items) do
          [
            {
              item_id: Faker::Number.number,
              item: Faker::Lorem.word,
              quantity_on_hand: Faker::Number.number,
              quantity_requested: Faker::Number.number
            }
          ]
        end

        before do
          allow(distribution).to receive(:storage_location).and_return(fake_storage_location)
          allow(distribution).to receive(:line_item_values).and_return(fake_insufficient_items)
          allow(fake_storage_location).to receive(:increase_inventory)
            .with(fake_insufficient_items)
            .and_raise(fake_insufficient_allotment_error)
        end

        it 'should not delete the Distribution' do
          expect { subject }.not_to change { Distribution.count }
        end

        it 'should not be successful and have the error message' do
          result = subject
          expect(result).not_to be_success
          expect(result.error).to be_instance_of(Errors::InsufficientAllotment)
        end
      end
    end
  end
end
