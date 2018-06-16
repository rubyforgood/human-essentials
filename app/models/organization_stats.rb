class OrganizationStats
  delegate :partners,
           :storage_locations,
           :donation_sites,
           to: :current_organization, allow_nil: true

  def initialize(organization)
    @current_organization = organization
  end

  def partners_added
    return 0 unless partners
    partners.length
  end

  def storage_locations_added
    return 0 unless storage_locations
    storage_locations.length
  end

  def donation_sites_added
    return 0 unless donation_sites
    donation_sites.length
  end

  def locations_with_inventory
    return [] unless storage_locations
    storage_locations.select { |location| location.inventory_items.present? }
  end

  private

  attr_reader :current_organization
end