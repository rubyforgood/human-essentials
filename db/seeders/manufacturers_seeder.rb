class ManufacturersSeeder
  def self.seed(org)
    [
      { name: "Manufacturer 1", organization: org },
      { name: "Manufacturer 2", organization: org }
    ].each { |manu| Manufacturer.find_or_create_by! manu }
  end
end
