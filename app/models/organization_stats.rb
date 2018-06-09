class OrganizationStats
  delegate :partners,
           :storage_locations,
           :donation_sites,
           to: :current_organization

  def initialize(organization)
    @current_organization = organization
  end

  def partners_added
    partners.length
  end

  def storage_locations_added
    storage_locations.length
  end

  def donation_sites_added
    donation_sites.length
  end

  def locations_with_inventory
    storage_locations.select{ |location| location.inventory_items.present? }
  end

  private

  attr_reader :current_organization
end