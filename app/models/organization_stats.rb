# TODO: Move this out of models
# Creates a service object to provide macros for some common organization stats
# These are largely used in the Organization dashboard.
class OrganizationStats
  delegate :partners,
           :storage_locations,
           :donation_sites,
           to: :current_organization, allow_nil: true

  def initialize(organization, inventory)
    @current_organization = organization
    @inventory = inventory
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

  def num_locations_with_inventory
    return 0 unless storage_locations

    storage_locations.count { |loc| inventory.quantity_for(storage_location: loc.id).positive? }
  end

  private

  attr_reader :current_organization, :inventory
end
