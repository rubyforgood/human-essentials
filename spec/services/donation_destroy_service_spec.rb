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
      before do
        allow(DonationDestroyEvent).to receive(:publish).and_raise('OH NOES')
      end

      it 'to not be a success' do
        result = subject.call
        expect(result).not_to be_success
      end
    end

    context 'when the donation destroy fails' do
      before do
        allow(DonationDestroyEvent).to receive(:publish).and_raise('OH NOES')
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
