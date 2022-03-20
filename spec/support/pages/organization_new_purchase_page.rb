require_relative "organization_page"

class OrganizationNewPurchasePage < OrganizationPage
  def org_page_path
    # relative path within organization's subtree
    "purchases/new"
  end
end
