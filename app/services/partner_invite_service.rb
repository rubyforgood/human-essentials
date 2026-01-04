class PartnerInviteService
  include ServiceObjectErrorsMixin

  def initialize(partner:, force: false)
    @partner = partner
    @force = force
  end

  def call
    partner.update!(status: 'invited')
    UserInviteService.invite(email: partner.email,
      name: partner.name,
      roles: [Role::PARTNER],
      resource: partner,
      force: @force)
  rescue => e
    errors.add(:base, e.message)
  end

  attr_reader :partner
end
