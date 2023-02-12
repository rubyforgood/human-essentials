# Encapsulates methods that need some business logic
module OrganizationHelper
  def display_logo_or_name(organization = nil)
    organization ||= current_organization
    organization.logo.attached? ? image_tag(organization.logo, alt: "#{organization.name} logo", class: "organization-logo", style: "max-height:188px") : organization.name
  end
end
