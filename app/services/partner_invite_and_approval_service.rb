class PartnerInviteAndApprovalService
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

    return self unless valid?

    Partners::Base.transaction do
      partner.approved!

      PartnerMailer.application_approved(partner: partner).deliver_later
    rescue StandardError => e
      errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    end
    self
  end

  private

  attr_reader :partner

  def valid?
    unless partner.approvable?
      errors.add(:partner, 'is not waiting for approval')
    end

    errors.none?
  end
end
