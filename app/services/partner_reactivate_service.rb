class PartnerReactivateService
  include ServiceObjectErrorsMixin

  attr_reader :partner

  def initialize(partner:)
    @partner = partner
  end

  def call
    ActiveRecord::Base.transaction do
      partners_partner = Partners::Partner.find_by!(partner_id: partner.id)

      partner.update!(status: 'approved')
      partners_partner.update!(status_in_diaper_base: 'approved', partner_status: 'verified')
    rescue StandardError => e
      errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    end

    self
  end
end
