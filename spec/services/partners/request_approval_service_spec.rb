require 'rails_helper'

describe Partners::RequestApprovalService, skip_seed: true do
  describe '#call' do
    subject { described_class.new(partner: partner).call }
    let(:partner) { create(:partner) }

    it 'should return an instance of itself' do
      expect(subject).to be_a_kind_of(Partners::RequestApprovalService)
    end

    context 'when the partner is already awaiting approval' do
      before do
        partner.profile.update!(partner_status: 'submitted')
      end

      it 'should return an error saying it the partner is already requested approval' do
        expect(subject.errors[:base]).to eq(["partner has already requested approval"])
      end
    end

    context 'when the partner is not yet awaiting approval' do
      let(:fake_mailer) { double('fake_mailer', deliver_later: -> {}) }
      before do
        allow(OrganizationMailer).to receive(:partner_approval_request).with(partner: partner, organization: partner.organization).and_return(fake_mailer)
        expect(partner.profile.partner_status).not_to eq('submitted')
      end

      it 'should set the partner_status of the partner profile to submitted' do
        expect { subject }.to change { partner.profile.reload.partner_status }.to('submitted')
      end

      it 'should set the status on the partner record to awaiting_review' do
        expect { subject }.to change { partner.awaiting_review? }.from(false).to(true)
      end

      it 'should send an email notification to the partner\'s organization' do
        subject
        expect(fake_mailer).to have_received(:deliver_later)
      end
    end
  end
end
