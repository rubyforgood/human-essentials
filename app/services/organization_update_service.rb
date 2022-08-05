class OrganizationUpdateService
  # @param organization [Organization]
  # @param params [ActionDispatch::Http::Parameters]
  # @return [Boolean]
  def self.update(organization, params)
    result = organization.update(params)
    return false unless result

    sync_visible_partner_form_sections(organization)
    update_child_enabled_flag(organization)
    true
  end

  # @param organization [Organization]
  def self.sync_visible_partner_form_sections(organization)
    return unless organization.saved_change_to_attribute?(:partner_form_fields)

    partner_form = Partners::PartnerForm.where(essentials_bank_id: organization.id).first_or_create
    partner_form.update!(sections: organization.partner_form_fields)
  end

  # @param organization [Organization]
  def self.update_child_enabled_flag(organization)
    return unless organization.saved_change_to_attribute?(:enable_child_based_requests)
    organization.partners.map(&:profile).each do |profile|
      profile.update!(enable_child_based_requests: organization.enable_child_based_requests)
    end
  end
end
