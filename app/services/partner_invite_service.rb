class PartnerInviteService
  include ServiceObjectErrorsMixin

  def initialize(partner:)
    @partner = partner
  end

  def call
    return self unless valid?

    partner.update!(status: 'invited')
    User.invite!(email: partner.email, partner: partner.profile)
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
