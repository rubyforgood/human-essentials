require_relative "organization_page"

class OrganizationNewDonationPage < OrganizationPage
  def org_page_path
    # relative path within organization's subtree
    "donations/new"
  end
end
