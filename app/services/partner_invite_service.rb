class PartnerInviteService
  include ServiceObjectErrorsMixin

  def initialize(partner:)
    @partner = partner
  end

  def call
    existing_user = User.find_by(email: partner.email)
    if existing_user && existing_user.partner_id.nil?
      existing_user.update!(partner_id: partner.profile.id)
      return self
    end

    partner.update!(status: 'invited')
    UserInviteService.invite(email: partner.email,
      roles: [Role::PARTNER],
      resource: partner)
  end

  attr_reader :partner
end
