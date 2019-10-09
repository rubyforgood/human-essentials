class VendorsSeeder

  def self.seed
    5.times do
      Vendor.create(
        contact_name: Faker::FunnyName.two_word_name,
        email: Faker::Internet.email,
        phone: Faker::PhoneNumber.cell_phone,
        comment: Faker::Lorem.paragraph(sentence_count: 2),
        organization_id: Organization.all.pluck(:id).sample,
        address: "#{Faker::Address.street_address} #{Faker::Address.city}, #{Faker::Address.state_abbr} #{Faker::Address.zip_code}",
        business_name: Faker::Company.name,
        latitude: rand(-90.000000000...90.000000000),
        longitude: rand(-180.000000000...180.000000000),
        created_at: (Date.today - rand(15).days),
        updated_at: (Date.today - rand(15).days),
      )
    end
  end
end
