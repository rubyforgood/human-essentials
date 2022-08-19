class PartnerUserInviteService
  include ServiceObjectErrorsMixin

  def initialize(partner:, email:)
    @partner = partner
    @email = email
  end

  def call
    if existing_partner_user.present?
      existing_partner_user.invite!
    else
      existing_user = User.find_by(email: email)
      if existing_user && existing_user.partner_id.nil?
        existing_user.update!(partner_id: partner.profile.id)
        return
      end
      User.invite!(email: email, partner: partner.profile)
    end
  end

  private

  attr_reader :partner, :email

  def existing_partner_user
    @existing_partner_user ||= User.find_by(email: email, partner: partner.profile)
  end
end
