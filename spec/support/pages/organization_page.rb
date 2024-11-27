require_relative "system_spec_page"

class OrganizationPage < SystemSpecPage
  attr_reader :org_short_name

  def initialize(org_short_name:)
    @org_short_name = org_short_name
  end

  def path
    # Implement org_page_path on subclasses
    "/" + org_short_name + "/" + org_page_path
  end

  def org_page_path
    raise NotImplementedError, "This #{self.class} cannot respond to:"
  end
end
