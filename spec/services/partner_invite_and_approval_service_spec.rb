require 'rails_helper'

describe PartnerInviteAndApprovalService do
  subject { described_class.new(partner: partner).call }
  let(:partner) { create(:partner) }
  let(:partner_profile) { partner.profile }

  context 'when the user has already been invited' do
    before do
      expect(partner.primary_user).not_to eq(nil)
    end

    it 'should return an error saying they are invited already' do
      expect(subject.errors).to be_empty
    end
  end

  context 'when the user has not been invited yet' do
    let(:partner) do
      partner = create(:partner, :uninvited)
      partner.primary_user.delete
      partner.reload
      partner
    end

    let(:user) { instance_double(User, reload: -> {}, deliver_invitation: -> {}) }
    let(:fake_mailer) { double('fake_mailer', deliver_later: -> {}) }
    before do
      allow(UserInviteService).to receive(:invite).and_return(user)
      allow(PartnerMailer).to receive(:application_approved).with(partner: partner).and_return(fake_mailer)
    end

    it 'should have no errors' do
        result = subject
        expect(result).to be_a_kind_of(PartnerInviteAndApprovalService)
        expect(result.errors).to be_empty
    end

    it 'should update the status of the partner to approved' do
      expect { subject }.to change { partner.reload.approved? }.from(false).to(true)
    end

    it 'should create invite' do
      subject
      expect(UserInviteService).to have_received(:invite).with(
        email: partner.email,
        roles: [Role::PARTNER],
        resource: partner
      )
    end

    context 'but a unexpected error occured during the save' do
      let(:error_message) { 'boom' }

      context 'for partner approval' do
          before do
            allow(partner).to receive(:approved!).and_raise(error_message)
          end

          it 'should have an error with the raised error' do
            expect(subject.errors[:base]).to eq([error_message])
          end

          it 'should not change the partner status to approved' do
            expect { subject }.not_to change { partner.reload.approved? }
          end
      end
    end
  end
end
