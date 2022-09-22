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
    # skip invitation is necessary because when email will be send for this situation needs partner reference updated,
    # and, in this case, we create invite, reload object and send invitation email.
    user = User.invite!(email: partner.email, partner: partner.profile, skip_invitation: true)

    user.reload
    user.deliver_invitation
  end

  attr_reader :partner
end
