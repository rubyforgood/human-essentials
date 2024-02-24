class PartnerInviteService
  include ServiceObjectErrorsMixin

  def initialize(partner:, force: false)
    @partner = partner
    @force = force
  end

  def call
    existing_user = User.find_by(email: partner.email)
    if existing_user && existing_user.partner_id.nil?
      existing_user.update!(partner_id: partner.profile.id)
    end

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
