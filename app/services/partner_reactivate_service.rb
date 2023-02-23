class PartnerReactivateService
  include ServiceObjectErrorsMixin

  attr_reader :partner

  def initialize(partner:)
    @partner = partner
  end

  def call
    ActiveRecord::Base.transaction do
      partner.update!(status: 'approved')
    rescue StandardError => e
      errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    end

    self
  end
end
