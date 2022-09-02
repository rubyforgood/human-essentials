class PartnerInviteService
  include ServiceObjectErrorsMixin

  def initialize(partner:)
    @partner = partner
  end

  def call
    return self unless valid?

    existing_user = User.find_by(email: partner.email)
    if existing_user && existing_user.partner_id.nil?
      existing_user.update!(partner_id: partner.profile.id)
      return
    end

    partner.update!(status: 'invited')
    UserInviteService.invite(email: partner.email,
      roles: %i[partner],
      resource: partner.profile)
  end

  private

  attr_reader :partner

  def valid?
    if partner.profile.primary_user
      errors.add(:base, "Partner has already been invited")
    end

    errors.blank?
  end
end
