class PartnerCreateService
  include ServiceObjectErrorsMixin

  attr_reader :partner

  def initialize(organization:, partner_attrs:)
    @organization = organization
    @partner_attrs = partner_attrs
  end

  def call
    process_default_storage_location

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

  def process_default_storage_location
    return unless partner_attrs.has_key?("default_storage_location")

    if partner_attrs["default_storage_location"].blank?
      partner_attrs.delete("default_storage_location")
    else
      default_storage_location_name = partner_attrs["default_storage_location"]&.titlecase
      default_storage_location_id = StorageLocation.find_by(
        name: default_storage_location_name,
        organization: organization.id
      )&.id

      if default_storage_location_id.nil?
        add_warning(:default_storage_location,
          "is not a storage location for this partner's organization")
      end

      partner_attrs.delete("default_storage_location")
      partner_attrs["default_storage_location_id"] = default_storage_location_id
    end
  end

  attr_reader :organization, :partner_attrs
end
