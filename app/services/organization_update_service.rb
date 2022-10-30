class OrganizationUpdateService
  # @param organization [Organization]
  # @param params [ActionDispatch::Http::Parameters]
  # @return [Boolean]
  def self.update(organization, params)
    result = organization.update(params)
    return false unless result

    update_partner_flags(organization)
    true
  end

  # @param organization [Organization]
  def self.update_partner_flags(organization)
    fields = %i[enable_child_based_requests enable_individual_requests]
    fields.each do |field|
      next unless organization.saved_change_to_attribute?(field)
      organization.partners.map(&:profile).each do |profile|
        profile.update!(field => organization.send(field))
      end
    end
  end
end
