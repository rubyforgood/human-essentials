class OrganizationUpdateService
  class << self
    FIELDS = %i[
      enable_child_based_requests
      enable_individual_requests
      enable_quantity_based_requests
    ]

    # @param organization [Organization]
    # @param params [ActionDispatch::Http::Parameters]
    # @return [Boolean]
    def update(organization, params)
      return false unless valid?(organization, params)

      org_params = params.dup

      if org_params.has_key?("partner_form_fields")
        org_params["partner_form_fields"] = org_params["partner_form_fields"].reject(&:blank?)
      end

      if Flipper.enabled?(:enable_packs) && org_params[:request_unit_names]
        # Find or create units for the organization
        request_unit_ids = org_params[:request_unit_names].reject(&:blank?).map do |request_unit_name|
          Unit.find_or_create_by(organization: organization, name: request_unit_name).id
        end
        org_params.delete(:request_unit_names)
        org_params[:request_unit_ids] = request_unit_ids
      end

      result = organization.update(org_params)

      return false unless result
      update_partner_flags(organization)
      true
    end

    # @param organization [Organization]
    def update_partner_flags(organization)
      FIELDS.each do |field|
        # If organization.send(field) is true then that means a
        # request type on the organization has been enabled.
        # We don't want to automatically enable the request type
        # on a partner. This should be left up to
        # individual partners to decide themselves as per:
        # github.com/rubyforgood/human-essentials/issues/3264
        next if organization.send(field)
        organization.partners.each do |partner|
          partner.profile.update!(field => organization.send(field))
        end
      end
    end

    private

    def valid?(organization, params)
      fields_marked_for_disabling = FIELDS.select { |field| params[field] == false }
      # Here we do a check: if applying the params for disabling request types to all
      # partners would mean any one partner would have all its request types disabled,
      # then we should not apply the params and return an error message. As per:
      # github.com/rubyforgood/human-essentials/issues/3264
      invalid_partner_names = find_invalid_partners(organization, fields_marked_for_disabling).map(&:name)
      if invalid_partner_names.empty?
        true
      else
        organization.errors.add(:base, "The following partners would be unable to make requests with this update: #{invalid_partner_names.join(", ")}")
        false
      end
    end

    def find_invalid_partners(organization, fields_marked_for_disabling)
      # finds any partners who's request types will all be disabled
      organization.partners.select do |partner|
        all_fields_will_be_disabled?(partner, fields_marked_for_disabling)
      end
    end

    def all_fields_will_be_disabled?(partner, fields_marked_for_disabling)
      enabled_fields = FIELDS.select { |field| partner.profile.send(field) == true }

      (enabled_fields - fields_marked_for_disabling).empty?
    end
  end
end
