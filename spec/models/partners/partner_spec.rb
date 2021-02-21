require "rails_helper"

RSpec.describe Partners::Partner, type: :model do
  describe 'associations' do
    it { should have_one(:user).dependent(:destroy) }
    it { should have_many(:requests).dependent(:destroy) }
    it { should have_many(:families).dependent(:destroy) }
    it { should have_many(:children).through(:families) }
    it { should have_one(:partner_form).with_primary_key(:diaper_bank_id).with_foreign_key(:diaper_bank_id).dependent(:destroy) }
    it { should have_one_attached(:proof_of_partner_status) }
    it { should have_one_attached(:proof_of_form_990) }
    it { should have_many_attached(:documents) }
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
end


