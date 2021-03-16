require 'rails_helper'

describe Partners::RequestApproval do
  describe '#call' do
    subject { described_class.new(partner: partner).call }
    let(:partner) { create(:partner) }

    it 'should return an instance of itself' do
      expect(subject).to be_a_kind_of(Partners::RequestApproval)
    end

    context 'when the partner is already awaiting approval' do
      before do
        partner.update!(partner_status: 'submitted')
      end

      it 'should return an error saying it the partner is already requested approval' do
        expect(subject.errors[:name]).to eq(["partner has already requested approval"])
      end
    end

  end
end
