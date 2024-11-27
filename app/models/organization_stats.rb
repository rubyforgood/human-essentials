# TODO: Move this out of models
# Creates a service object to provide macros for some common organization stats
# These are largely used in the Organization dashboard.
class OrganizationStats
  delegate :partners,
           :storage_locations,
           :donation_sites,
           to: :current_organization, allow_nil: true

  def initialize(organization)
    @current_organization = organization
  end

  def partners_added
    partners&.length || 0
  end

  def storage_locations_added
    storage_locations&.length || 0
  end

  def donation_sites_added
    donation_sites&.length || 0
  end

  def locations_with_inventory
    return [] unless storage_locations

    inventoried_storage_location_ids = InventoryItem.where(storage_location: storage_locations).pluck(:storage_location_id)
    storage_locations.select { |location| inventoried_storage_location_ids.include? location.id }
  end

  private

  attr_reader :current_organization
end
