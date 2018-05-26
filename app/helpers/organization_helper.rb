module OrganizationHelper
  def display_logo_or_name organization = nil
    organization ||= current_organization
    organization.logo.present? ? image_tag(organization.logo.url, alt: "#{organization.name} logo", class: "organization-logo", style:"max-height:188px") : organization.name
  end
end
