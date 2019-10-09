class StorageLocationsSeeder
  def self.seed(org, name)
    StorageLocation.find_or_create_by!(name: name) do |inventory|
      inventory.address = "Unknown"
      inventory.organization = org
    end
  end
end
