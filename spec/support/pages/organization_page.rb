require_relative "system_spec_page"

class OrganizationPage < SystemSpecPage
  def path
    # Implement org_page_path on subclasses
    "/" + org_page_path
  end

  def org_page_path
    raise NotImplementedError, "This #{self.class} cannot respond to:"
  end
end
