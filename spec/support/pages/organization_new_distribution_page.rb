class OrganizationNewDistributionPage < OrganizationPage
  def org_page_path
    # relative path within organization's subtree
    "distributions/new"
  end
end
