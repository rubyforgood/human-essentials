require_relative "organization_page"

class OrganizationDonationsPage < OrganizationPage
  def org_page_path
    # relative path within organization's subtree
    "donations"
  end

  def create_new_donation
    # "New Donation" isn't unique on the page, but this is
    find("a.btn i.fa-plus").click
  end
end