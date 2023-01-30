# Encapsulates methods that need some business logic
module OrganizationHelper
  def display_logo_or_name(organization = nil)
    organization ||= current_organization
    organization.logo.attached? ? image_tag(organization.logo, alt: "#{organization.name} logo", class: "organization-logo", style: "max-height:188px") : organization.name
  end

  def display_partner_fields_value(stored_value)
    display_value, _ = Organization::ALL_PARTIALS.detect { |arr| arr[1] == stored_value }
    display_value
  end
end
