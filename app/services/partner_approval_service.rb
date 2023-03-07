class PartnerApprovalService
  include ServiceObjectErrorsMixin

  def initialize(partner:)
    @partner = partner
  end

  def call
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
