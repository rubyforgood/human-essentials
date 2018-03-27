module OrganizationHelper
  def display_logo_or_name(organization = nil)
    organization ||= current_organization
    if organization.logo.present?
      image_tag(organization.logo, alt: "#{organization.name} logo",
                                   class: "organization-logo",
                                   style: "max-height:188px")
    else
      organization.name
    end
  end
end
