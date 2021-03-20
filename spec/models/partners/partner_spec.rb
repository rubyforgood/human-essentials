require "rails_helper"

RSpec.describe Partners::Partner, type: :model do
  describe 'associations' do
    it { should have_many(:users).dependent(:destroy) }
    it { should have_many(:requests).dependent(:destroy) }
    it { should have_many(:families).dependent(:destroy) }
    it { should have_many(:children).through(:families) }
    it { should have_one(:partner_form).with_primary_key(:diaper_bank_id).with_foreign_key(:diaper_bank_id).dependent(:destroy) }
    it { should have_one_attached(:proof_of_partner_status) }
    it { should have_one_attached(:proof_of_form_990) }
    it { should have_many_attached(:documents) }

    describe 'primary_user' do
      subject { partner.primary_user }
      let(:partner) { create(:partner).profile }
      before do
        second_user = partner.primary_user.clone
        second_user.email = Faker::Internet.email
        second_user.save!
      end

      it 'should return the first user ever created for a partner' do
        expect(subject).to eq(partner.primary_user)
      end
    end
  end

  describe '#verified?' do
    subject { partner.verified? }
    let(:partner) { FactoryBot.build(:partners_partner, partner_status: partner_status) }

    context 'when the partner_status is verified' do
      let(:partner_status) { 'verified' }

      it 'should return true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the partner_status i not verified' do
      let(:partner_status) { 'not-verified' }

      it 'should return false' do
        expect(subject).to eq(false)
      end
    end
  end

  describe '#organization' do
    subject { partner.organization }
    let(:partner) { FactoryBot.create(:partners_partner) }

    it 'should return the associated organization using its diaper bank id' do
      expect(subject).to eq(Organization.find_by!(id: partner.diaper_bank_id))
    end
  end

  describe '#impact_metrics' do
    subject { partner.impact_metrics }
    let(:partner) { FactoryBot.create(:partners_partner) }

    context 'when partner has related informations' do
      let!(:family1) { FactoryBot.create(:partners_family, guardian_zip_code: '45612-123', partner: partner) }
      let!(:family2) { FactoryBot.create(:partners_family, guardian_zip_code: '45612-126', partner: partner) }
      let!(:family3) { FactoryBot.create(:partners_family, guardian_zip_code: '45612-123', partner: partner) }

      let!(:child1) { FactoryBot.create_list(:partners_child, 2, family: family1) }
      let!(:child2) { FactoryBot.create_list(:partners_child, 2, family: family3) }

      it { is_expected.to eq({ families_served: 3, children_served: 4, family_zipcodes: 2, family_zipcodes_list: %w(45612-123 45612-126) }) }
    end

    context "when partner don't have any related informations" do
      it { is_expected.to eq({ families_served: 0, children_served: 0, family_zipcodes: 0, family_zipcodes_list: [] }) }
    end
  end
end


