class PartnerCreateService
  include ServiceObjectErrorsMixin

  attr_reader :partner

  def initialize(organization:, partner_attrs:)
    @organization = organization
    @partner_attrs = partner_attrs
  end

  def call
    @partner = organization.partners.build(partner_attrs)

    unless @partner.valid?
      @partner.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end

    ActiveRecord::Base.transaction do
      @partner.save!

      Partners::Partner.create!({
                                  essentials_bank_id: organization.id,
                                  partner_id: @partner.id,
                                  name: @partner.name,
                                  enable_child_based_requests: organization.enable_child_based_requests
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
