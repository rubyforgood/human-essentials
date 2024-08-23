RSpec.describe PartnerCreateService do
  describe '#call' do
    subject { described_class.new(organization: organization, partner_attrs: partner_attrs).call }
    let(:organization) {
      create(:organization,
        enable_individual_requests: false,
        enable_child_based_requests: false,
        enable_quantity_based_requests: true)
    }
    let(:partner_attrs) { FactoryBot.attributes_for(:partner).except(:organization_id) }

    it 'should return an instance of itself' do
      expect(subject).to be_a_kind_of(PartnerCreateService)
    end

    context 'when the arguments are incorrect' do
      context 'beacuse the partner_attrs are invalid' do
        let(:partner_attrs) { {} }
        let(:expected_partner_errors) do
          partner = Partner.new(partner_attrs)
          partner.valid?
          partner.errors.full_messages
        end

        it 'should contain errors related to invalid partner attributes' do
          result = subject

          expect(result.errors[:name]).to eq(["can't be blank"])
        end
      end
    end

    context 'when the arguments are valid' do
      it 'should create a new partner record with the organization provided' do
        expect { subject }.to change { organization.partners.count }.by(1)
      end

      it 'should create the associated partner profile data' do
        query = Partners::Profile.joins(:partner).where(partners: {name: partner_attrs[:name]})
        expect { subject }.to change { query.count }.from(0).to(1)
        expect(query.first.enable_child_based_requests).to eq(false)
        expect(query.first.enable_individual_requests).to eq(false)
        expect(query.first.enable_quantity_based_requests).to eq(true)
      end

      context 'but there was an unexpected issue with saving the' do
        let(:error_message) { Faker::Games::ElderScrolls.dragon }

        context 'Partners::Profile record' do
          before do
            allow(Partners::Profile).to receive(:create!).and_raise(error_message)
          end

          it 'should not create the partner record for the organization' do
            expect { subject }.not_to change { organization.partners.count }
          end

          it 'should not create the associated partner records' do
            expect { subject }.not_to change { organization.partners.count }
          end
        end

        context 'Partner record' do
          before do
            allow_any_instance_of(Partner).to receive(:save!).and_raise(error_message)
          end

          it 'should not create the partner record for the organization' do
            expect { subject }.not_to change { organization.partners.count }
          end

          it 'should not create the associated partner records' do
            expect { subject }.not_to change { organization.partners.count }
          end
        end
      end
    end
  end
end

