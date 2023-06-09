class PartnerRequestRecertificationService
  include ServiceObjectErrorsMixin

  # Creates a new instance of PartnerRequestRecertificationService
  #
  # @param partner: [Partner] the partner record
  #
  # @return [PartnerRequestRecertificationService]
  def initialize(partner:)
    @partner = partner
  end

  def call
    return self unless valid?

    Partners::Base.transaction do
      partner.recertification_required!
      PartnerMailer.recertification_request(partner: partner).deliver_later
    rescue StandardError => e
      errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    end

    self
  end

  private

  attr_reader :partner

  def valid?
    if partner.recertification_required?
      errors.add(:partner, 'has already been requested to recertify')
    elsif partner.deactivated?
      errors.add(:partner, 'has been deactivated')
    end

    errors.none?
  end
end
