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
    inventoried_storage_location_ids = InventoryItem.where(storage_location: storage_locations).pluck(:storage_location_id)
    storage_locations.select { |location| inventoried_storage_location_ids.include? location.id }
  end

  private

  attr_reader :current_organization
end
