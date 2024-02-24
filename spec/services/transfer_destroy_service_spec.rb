RSpec.describe TransferDestroyService, type: :service do
  describe '#call' do
    subject { described_class.new(transfer_id: transfer_id).call }
    let(:transfer_id) { transfer.id }
    let(:transfer) { create(:transfer, organization: organization) }
    let(:organization) { create(:organization) }
    # Create a double StorageLocation that behaves like how we want to use
    # it within the service object. The benefit is that we aren't testing
    # ActiveRecord and the database.
    let(:fake_from) { instance_double(StorageLocation, increase_inventory: -> {}, id: 1) }
    let(:fake_to) { instance_double(StorageLocation, decrease_inventory: -> {}, id: 1) }
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
      # Stub the outputs of these method calls to avoid testing
      # beyond this service objects responsiblity. That is we,
      # aren't interested in testing the implementation details
      # such as the database.
      allow(Transfer).to receive(:find).with(transfer_id).and_return(transfer)
      allow(transfer).to receive(:from).and_return(fake_from)
      allow(transfer).to receive(:to).and_return(fake_to)
      allow(transfer).to receive(:destroy!)
      allow(transfer).to receive(:line_item_values).and_return(fake_items)

      # Now that that the `transfer.from` and `transfer.to` is stubbed
      # to return the doubles of StorageLocation, we must program them
      # to expect the `increase_inventory` and `decrease_inventory`
      allow(fake_from).to receive(:increase_inventory).with(fake_items)
      allow(fake_to).to receive(:decrease_inventory).with(fake_items)
    end

    context 'when there are no issues' do
      it 'should return an OpenStruct with success? set to true' do
        expect { subject }.to change { TransferDestroyEvent.count }.by(1)
        expect(subject).to be_a_kind_of(OpenStruct)
        expect(subject.success?).to eq(true)
      end

      it 'should execute the expected methods' do
        # Invoke the subject aka call the service object call method
        subject

        # Assert that the service object calls the expected method.
        expect(fake_from).to have_received(:increase_inventory).with(fake_items)
        expect(fake_to).to have_received(:decrease_inventory).with(fake_items)
        expect(transfer).to have_received(:destroy!)
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

      context 'because undoing the transfer inventory changes by increasing the inventory of `from` failed' do
        let(:fake_error) { Errors::InsufficientAllotment.new('msg') }

        before do
          allow(transfer).to receive(:line_item_values).and_return(fake_items)
          allow(fake_from).to receive(:increase_inventory).with(fake_items).and_raise(fake_error)
        end

        it 'should return a OpenStruct with the raised error' do
          expect(subject).to be_a_kind_of(OpenStruct)
          expect(subject.success?).to eq(false)
          expect(subject.error).to eq(fake_error)
        end
      end

      context 'because undoing the transfer inventory changes by decreasing the inventory of `to` failed' do
        let(:fake_error) { Errors::InsufficientAllotment.new('random-error') }
        before do
          allow(transfer).to receive(:line_item_values).and_return(fake_items)
          allow(fake_to).to receive(:decrease_inventory).with(transfer.line_item_values).and_raise(fake_error)
        end

        it 'should return a OpenStruct with the raised error' do
          expect(subject).to be_a_kind_of(OpenStruct)
          expect(subject.success?).to eq(false)
          expect(subject.error).to eq(fake_error)
        end
      end

      context 'because the transfer destroy raised an error' do
        let(:fake_error) { StandardError.new('random-error') }
        before do
          allow(transfer).to receive(:destroy!).and_raise(fake_error)
        end

        it 'should return a OpenStruct with the raised error' do
          expect(subject).to be_a_kind_of(OpenStruct)
          expect(subject.success?).to eq(false)
          expect(subject.error).to eq(fake_error)
        end
      end
    end

    context 'because transfer should not be deleted' do
      before do
        allow(Audit).to receive(:finalized_since?).and_return(true)
      end

      it 'should return an OpenStruct with the raised error' do
        expect(subject).to be_a_kind_of(OpenStruct)
        expect(subject.success?).to eq(false)
        expect(subject.error).to be_a_kind_of(StandardError)
      end
    end
  end
end
