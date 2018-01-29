module OrganizationHelper
  def display_logo_or_name organization = nil
    organization ||= current_organization
    organization.logo.present? ? image_tag(organization.logo, alt: "#{organization.name} logo", class: "organization-logo") : organization.name
  end
end
