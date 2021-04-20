class PartnerDeactivateService
  include ServiceObjectErrorsMixin

  attr_reader :partner

  def initialize(partner:)
    @partner = partner
  end

  def call
    ActiveRecord::Base.transaction do
      partners_partner = Partners::Partner.find_by!(diaper_partner_id: partner.id)

      partner.update!(status: 'deactivated')
      partners_partner.update!(status_in_diaper_base: 'deactivated', partner_status: 'pending')
    rescue StandardError => e
      errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    end

    self
  end
end
