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
      if organization.update(params)
        update_partner_flags(organization)
      end
      organization
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
  end
end
