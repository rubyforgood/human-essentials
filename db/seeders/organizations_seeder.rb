class OrganizationsSeeder
  ORGANIZATIONS = [
    { name: "Pawnee Diaper Bank", street: "P.O. Box 22613", city: "Pawnee",
      state: "Indiana", zipcode: "12345",email: "info@pawneediaper.org",
      short_by: 'diaper_bank' },
    { name: "SF Diaper Bank", street: "P.O. Box 12345", city: "San Francisco",
      state: "CA", zipcode: "90210", email: "info@sfdiaperbank.org",
      short_by: "sf_bank" }
  ]

  def self.seed
    ORGANIZATIONS.each { |org| seed_items(find_or_create(org)) }
  end

  def self.find_or_create(org)
    Organization.find_or_create_by!(short_name: org[:short_by]) do |organization|
      organization.name = org[:name]
      organization.street = org[:street]
      organization.city = org[:city]
      organization.state = org[:state]
      organization.zipcode = org[:zipcode]
      organization.email = org[:email]
    end
  end

  def self.seed_items(org)
    Organization.seed_items(org)
  end
end
