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
      if existing_user
        existing_user.add_role(:partner, partner.profile)
        return
      end
      User.invite!(email: email) do |user|
        user.add_role(:partner, partner.profile)
      end
    end
  end

  private

  attr_reader :partner, :email

  def existing_partner_user
    return @existing_partner_user if @existing_partner_user
    user = User.find_by(email: email)
    return nil unless user&.has_role?(:partner, partner.profile)
    @existing_partner_user = user
  end
end
