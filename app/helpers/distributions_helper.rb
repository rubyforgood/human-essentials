module DistributionsHelper
  def logo_file_path(organization = nil)
    if organization&.logo&.attached?
      organization.logo.path
    else
      Rails.root.join("app", "assets", "images", "DiaperBase-Logo.png")
    end
  end
end
