RSpec.describe DonationDestroyService do
  describe '#call' do
    subject { described_class.new(organization_id: organization_id, donation_id: donation_id) }
    let(:organization_id) { Faker::Number.number }
    let(:donation_id) { Faker::Number.number }

    context 'when the organization_id matches no Organization' do
      before do
        allow(Organization).to receive(:find)
          .with(organization_id)
          .and_raise(ActiveRecord::RecordNotFound)
      end

      it 'to not be a success' do
        result = subject.call
        expect(result).not_to be_success
      end
    end

    context 'when the donation_id matches no Donation owned by the organization' do
      let(:fake_organization) { instance_double(Organization, donations: fake_organization_donations) }
      let(:fake_organization_donations) { instance_double('donations') }

      before do
        allow(Organization).to receive(:find)
          .with(organization_id)
          .and_return(fake_organization)
        allow(fake_organization_donations).to receive(:find)
          .with(donation_id)
          .and_raise(ActiveRecord::RecordNotFound)
      end

      it 'to not be a success' do
        result = subject.call
        expect(result).not_to be_success
      end
    end

    context 'when storage_location fails to decrease the inventory of the donation' do
      let(:fake_organization) { instance_double(Organization, short_name: 'org_name', donations: fake_organization_donations) }
      let(:fake_organization_donations) { instance_double('donations') }
      let(:fake_donation) { instance_double(Donation, storage_location: fake_storage_location) }
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
        allow(Organization).to receive(:find)
          .with(organization_id)
          .and_return(fake_organization)
        allow(fake_organization_donations).to receive(:find)
          .with(donation_id)
          .and_return(fake_donation)
        allow(fake_donation).to receive(:line_item_values).and_return(fake_insufficient_items)
        allow(fake_storage_location).to receive(:decrease_inventory)
          .with(fake_insufficient_items)
          .and_raise(fake_insufficient_allotment_error)
      end

      it 'to not be a success' do
        result = subject.call
        expect(result).not_to be_success
        expect(result.error).to be_instance_of(Errors::InsufficientAllotment)
      end
    end

    context 'when the donation destroy fails' do
      let(:fake_organization) { instance_double(Organization, short_name: 'org_name', donations: fake_organization_donations) }
      let(:fake_organization_donations) { instance_double('donations') }
      let(:fake_donation) {
        instance_double(Donation,
          storage_location: fake_storage_location,
          storage_location_id: 12,
          id: 5,
          line_items: [],
          organization_id: organization_id)
      }
      let(:fake_storage_location) { instance_double(StorageLocation) }
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
        allow(Organization).to receive(:find)
          .with(organization_id)
          .and_return(fake_organization)
        allow(fake_organization_donations).to receive(:find)
          .with(donation_id)
          .and_return(fake_donation)
        allow(fake_donation).to receive(:line_item_values).and_return(fake_insufficient_items)
        allow(fake_storage_location).to receive(:decrease_inventory).with(fake_insufficient_items)
        allow(fake_donation).to receive(:destroy!).and_raise('boom')
      end

      it 'to not be a success' do
        result = subject.call
        expect(result).not_to be_success
      end
    end

    context 'when the donation succesfully gets destroyed' do
      let(:donation) { FactoryBot.create(:donation) }
      subject {
        described_class.new(organization_id: donation.organization_id,
          donation_id: donation.id)
      }

      it 'to be a success' do
        result = subject.call
        expect(result).to be_success
        expect(DonationDestroyEvent.count).to eq(1)
      end
    end
  end
end
