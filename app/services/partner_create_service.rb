class PartnerCreateService
  include ServiceObjectErrorsMixin

  def initialize(organization:, partner_attrs:)
    @organization = organization
    @partner_attrs = partner_attrs
  end

  def call
    partner = organization.partners.build(partner_attrs)

    unless partner.valid?
      partner.errors.each do |k, v|
        errors.add(k, v)
      end
    end

    ActiveRecord::Base.transaction do
      partner.save!

      Partners::Partner.create!({
                                  diaper_bank_id: organization.id,
                                  diaper_partner_id: partner.id,
                                  name: partner.name
                                })
    rescue StandardError => e
      errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    end

    self
  end

  private

  attr_reader :organization, :partner_attrs
end
