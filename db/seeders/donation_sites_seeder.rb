class DonationSitesSeeder
  SITES = [
    { name: "Pawnee Hardware", address: "1234 SE Some Ave., Pawnee, OR 12345" },
    { name: "Parks Department", address: "2345 NE Some St., Pawnee, OR 12345" },
    { name: "Waffle House", address: "3456 Some Bay., Pawnee, OR 12345" },
    { name: "Eagleton Country Club", address: "4567 Some Blvd., Eagleton, OR 12345" }
  ].freeze

  def self.seed(org)
    SITES.each do |site|
      DonationSite.find_or_create_by!(name: site[:name]) do |location|
        location.address = site[:address]
        location.organization = org
      end
    end
  end
end
