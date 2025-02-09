RSpec.describe ItemCreateService, type: :service do
  describe '#call' do
    subject { described_class.new(organization_id: organization_id, item_params: item_params).call }
    let(:organization_id) { organization.id }
    let(:item_params) { { fake: 'param' } }
    let(:organization) { create(:organization) }
    let(:fake_organization_items) { instance_double('organization.items') }
    let(:fake_organization_item) { instance_double(Item, id: 99_999, save!: -> {}) }
    let(:fake_organization_storage_locations) do
      [
        instance_double(StorageLocation, id: 'fake-id-1'),
        instance_double(StorageLocation, id: 'fake-id-2')
      ]
    end

    before do
      # Utilize mocks to isolate the tests to prevent accessing
      # the database. And prevent testing ActiveRecord or the
      # actual database.
      #
      # By doing it this way, we remove extra dependencies on the
      # database.
      allow(Organization).to receive(:find).with(organization_id).and_return(organization)
      allow(organization).to receive(:items).and_return(fake_organization_items)
      allow(fake_organization_items).to receive(:new).with(item_params).and_return(fake_organization_item)
      allow(organization).to receive(:storage_locations).and_return(fake_organization_storage_locations)
    end

    context 'when there are no issues' do
      it 'should return a result object with success? returning true and the item' do
        expect(subject).to be_a_kind_of(Result)
        expect(subject.success?).to eq(true)
        expect(subject.value).to eq(fake_organization_item)
      end

      it 'should execute the expected methods' do
        # Invoke the subject aka call the service object call method
        subject

        # Assert that the service object calls the expected method.
        expect(fake_organization_item).to have_received(:save!)
      end
    end

    context 'when an issue occurs in transaction' do
      context 'because the organization_id does not match any Organization' do
        before do
          allow(Organization).to receive(:find).with(organization_id).and_raise(ActiveRecord::RecordNotFound)
        end

        it 'should return a result object with an ActiveRecord::RecordNotFound error' do
          expect(subject).to be_a_kind_of(Result)
          expect(subject.success?).to eq(false)
          expect(subject.error).to be_a_kind_of(ActiveRecord::RecordNotFound)
        end
      end

      context 'because the item create raised an error' do
        let(:fake_error) { StandardError.new('random-error') }

        before do
          allow(fake_organization_item).to receive(:save!).and_raise(fake_error)
        end

        it 'should return a result object with the raised error' do
          expect(subject).to be_a_kind_of(Result)
          expect(subject.success?).to eq(false)
          expect(subject.error).to eq(fake_error)
        end
      end
    end
  end
end
