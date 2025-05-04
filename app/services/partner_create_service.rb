class PartnerCreateService
  include ServiceObjectErrorsMixin

  attr_reader :partner

  def initialize(organization:, partner_attrs:)
    @organization = organization
    @partner_attrs = partner_attrs
  end

  def call
    if partner_attrs["default_storage_location"]
      default_storage_location_name = partner_attrs["default_storage_location"].titlecase
      default_storage_location_id = StorageLocation.find_by(name: default_storage_location_name)&.id
      partner_attrs.delete("default_storage_location")
      partner_attrs["default_storage_location_id"] = default_storage_location_id
    end
    @partner = organization.partners.build(partner_attrs)

    if @partner.valid?
      ActiveRecord::Base.transaction do
        @partner.save!

        Partners::Profile.create!({
                                    partner_id: @partner.id,
                                    name: @partner.name,
                                    enable_child_based_requests: organization.enable_child_based_requests,
                                    enable_individual_requests: organization.enable_individual_requests,
                                    enable_quantity_based_requests: organization.enable_quantity_based_requests
                                  })
      rescue StandardError => e
        errors.add(:base, e.message)
        raise ActiveRecord::Rollback
      end
    else
      @partner.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end

    self
  end

  private

  attr_reader :organization, :partner_attrs
end
