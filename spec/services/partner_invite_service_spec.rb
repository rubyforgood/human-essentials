RSpec.describe PartnerInviteService do
  subject { described_class.new(partner: partner).call }
  let(:partner) { create(:partner) }
  let(:user) { instance_double(User, reload: -> {}, deliver_invitation: -> {}) }

  before do
    allow(UserInviteService).to receive(:invite).and_return(user)
  end

  let(:partner) do
    partner = create(:partner, :uninvited)
    partner.primary_user.delete
    partner.reload
    partner
  end

  it 'should update the status of the partner to invited' do
    expect { subject }.to change { partner.status }.to('invited')
  end

  it 'should create invite' do
    subject
    expect(UserInviteService).to have_received(:invite).with(
      email: partner.email,
      name: partner.name,
      roles: [Role::PARTNER],
      resource: partner,
      force: false
    )
  end

  context 'with force: true' do
    subject { described_class.new(partner: partner, force: true).call }

    it 'should send the force setting forward' do
      subject
      expect(UserInviteService).to have_received(:invite).with(
        email: partner.email,
        name: partner.name,
        roles: [Role::PARTNER],
        resource: partner,
        force: true
      )
    end
  end
end
