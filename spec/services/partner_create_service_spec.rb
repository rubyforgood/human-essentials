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
      context 'because the partner_attrs are invalid' do
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

    context 'when the partner email already exists in a different organization' do
      let(:other_organization) { create(:organization) }

      before do
        create(:partner, email: partner_attrs[:email], organization: other_organization)
      end

      it 'should contain an error about the partner being with a different organization' do
        result = subject
        expect(result.errors[:email]).to include("has already been taken")
      end

      it 'should not create a new partner' do
        expect { subject }.not_to change { Partner.count }
      end
    end

    context 'when a default storage location name is provided' do
      let(:partner_attrs) do
        FactoryBot.attributes_for(:partner).except(:organization_id).stringify_keys
          .merge('default_storage_location' => provided_name)
      end

      context 'and it matches a storage location regardless of case' do
        let!(:storage_location) do
          create(:storage_location, organization: organization, name: 'SF Bay Warehouse')
        end

        ['SF Bay Warehouse', 'sf bay warehouse', 'SF BAY WAREHOUSE', '  SF Bay Warehouse  '].each do |name|
          context "when given #{name.inspect}" do
            let(:provided_name) { name }

            it 'assigns the storage location without warning' do
              result = subject

              expect(result.warnings).to be_empty
              expect(result.partner.default_storage_location_id).to eq(storage_location.id)
            end
          end
        end
      end

      context 'and the matching storage location has been discarded' do
        let(:provided_name) { 'Closed Depot' }
        let!(:storage_location) do
          create(:storage_location, organization: organization, name: provided_name).tap(&:discard)
        end

        it 'does not assign it and warns instead' do
          result = subject

          expect(result.partner.default_storage_location_id).to be_nil
          expect(result.warnings[:default_storage_location])
            .to include("is not a storage location for this partner's organization")
        end
      end

      context 'and it belongs to a different organization' do
        let(:provided_name) { 'Other Org Warehouse' }
        let!(:storage_location) do
          create(:storage_location, organization: create(:organization), name: provided_name)
        end

        it 'does not assign it and warns instead' do
          result = subject

          expect(result.partner.default_storage_location_id).to be_nil
          expect(result.warnings[:default_storage_location])
            .to include("is not a storage location for this partner's organization")
        end
      end

      context 'and no such storage location exists' do
        let(:provided_name) { 'Nonexistent Depot' }

        it 'creates the partner and warns' do
          result = subject

          expect(result.errors).to be_empty
          expect(result.partner).to be_persisted
          expect(result.partner.default_storage_location_id).to be_nil
          expect(result.warnings[:default_storage_location])
            .to include("is not a storage location for this partner's organization")
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

      context 'when send_reminders is nil' do
        before do
          partner_attrs.merge!(send_reminders: nil)
        end

        it 'defaults send_reminders to false' do
          subject

          partner = Partner.find_by(name: partner_attrs[:name])
          expect(partner.send_reminders).to be(false)
        end
      end

      context 'when send_reminders is missing' do
        before do
          partner_attrs.delete(:send_reminders)
        end

        it 'defaults send_reminders to false' do
          subject

          partner = Partner.find_by(name: partner_attrs[:name])
          expect(partner.send_reminders).to be(false)
        end
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
