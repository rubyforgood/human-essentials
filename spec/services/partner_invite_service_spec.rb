require 'rails_helper'

describe PartnerInviteService do
  subject { described_class.new(partner: partner).call }
  let(:partner) { create(:partner) }

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

    before do
      allow(UserInviteService).to receive(:invite).and_return(user)
    end

    it 'should update the status of the partner to invited' do
      expect { subject }.to change { partner.status }.to('invited')
    end

    it 'should create invite' do
      subject
      expect(UserInviteService).to have_received(:invite).with(
        email: partner.email,
        roles: [Role::PARTNER],
        resource: partner
      )
    end
  end
end
