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

      result = organization.update(params)
      return false unless result

      update_partner_flags(organization)
      true
    end

    # @param organization [Organization]
    def update_partner_flags(organization)
      FIELDS.each do |field|
        next if organization.send(field)
        organization.partners.map(&:profile).each do |profile|
          profile.update!(field => organization.send(field))
        end
      end
    end

    private

    def valid?(organization, params)
      return true unless organization.partners.any?

      disable_params = FIELDS.select { |field| params[field] == false }

      organization.partners.each do |partner|
        return false if disables_all_partner_fields?(partner, disable_params)
      end

      true
    end

    def disables_all_partner_fields?(partner, disable_params)
      enabled_fields = FIELDS.select { |field| partner.profile.send(field) == true }

      enabled_fields.all? { |field| disable_params.include?(field) }
    end
  end
end
