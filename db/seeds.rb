# This file should contain all the record creation needed to seed the database with demo values.
# The data can then be loaded with `rails db:seed` (or along with the creation of the db with `rails db:setup`).

if Rails.env.production?
  Rails.logger.info "Database seeding has been configured to work only in non production settings"
  return
end

# Activate all feature flags
Flipper.enable(:onebase)

# ----------------------------------------------------------------------------
# Random Record Generators
# ----------------------------------------------------------------------------

def random_record(klass)
  klass.limit(1).order(Arel.sql('random()')).first
end

def random_record_for_org(org, klass)
  klass.where(organization: org).limit(1).order(Arel.sql('random()')).first
end

# ----------------------------------------------------------------------------
# Script-Global Variables
# ----------------------------------------------------------------------------

# Initial starting qty for our test organizations
base_items = File.read(Rails.root.join("db", "base_items.json"))
items_by_category = JSON.parse(base_items)

# ----------------------------------------------------------------------------
# Base Items
# ----------------------------------------------------------------------------

items_by_category.each do |category, entries|
  entries.each do |entry|
    BaseItem.find_or_create_by!(name: entry["name"], category: category, partner_key: entry["key"])
  end
end

# Create global 'Kit' base item
BaseItem.find_or_create_by!(
  name: 'Kit',
  category: 'kit',
  partner_key: 'kit'
)

# ----------------------------------------------------------------------------
# Organizations
# ----------------------------------------------------------------------------

pdx_org = Organization.find_or_create_by!(short_name: "diaper_bank") do |organization|
  organization.name    = "Pawnee Diaper Bank"
  organization.street  = "P.O. Box 22613"
  organization.city    = "Pawnee"
  organization.state   = "Indiana"
  organization.zipcode = "12345"
  organization.email   = "info@pawneediaper.org"
end
Organization.seed_items(pdx_org)

sf_org = Organization.find_or_create_by!(short_name: "sf_bank") do |organization|
  organization.name    = "SF Diaper Bank"
  organization.street  = "P.O. Box 12345"
  organization.city    = "San Francisco"
  organization.state   = "CA"
  organization.zipcode = "90210"
  organization.email   = "info@sfdiaperbank.org"
end
Organization.seed_items(sf_org)

# Assign a value to some organization items to verify totals are working
Organization.all.each do |org|
  org.items.where(value_in_cents: 0).limit(10).each do |item|
    item.update(value_in_cents: 100)
  end
end

# ----------------------------------------------------------------------------
# Item Categories
# ----------------------------------------------------------------------------

Organization.all.each do |org|
  ['A', 'B', 'C'].each do |letter|
    FactoryBot.create(:item_category, organization: org, name: "Category #{letter}")
  end
end

# ----------------------------------------------------------------------------
# Item < - > ItemCategory
# ----------------------------------------------------------------------------

Organization.all.each do |org|
  # Added `nil` to randomly choose to not categorize items sometimes via sample
  item_category_ids = org.item_categories.map(&:id) + [nil]

  org.items.each do |item|
    item.update_column(:item_category_id, item_category_ids.sample)
  end
end

# ----------------------------------------------------------------------------
# Users
# ----------------------------------------------------------------------------

[
  { email: 'superadmin@example.com', organization_admin: false, super_admin: true },
  { email: 'org_admin1@example.com', organization_admin: true,  organization: pdx_org },
  { email: 'org_admin2@example.com', organization_admin: true,  organization: sf_org },
  { email: 'user_1@example.com',     organization_admin: false, organization: pdx_org },
  { email: 'user_2@example.com',     organization_admin: false, organization: sf_org },
  { email: 'test@example.com',       organization_admin: false, organization: pdx_org, super_admin: true },
  { email: 'test2@example.com',      organization_admin: true,  organization: pdx_org }
].each do |user|
  User.create(
    email: user[:email],
    password: 'password',
    password_confirmation: 'password',
    organization_admin: user[:organization_admin],
    super_admin: user[:super_admin],
    organization: user[:organization]
  )
end

# ----------------------------------------------------------------------------
# Donation Sites
# ----------------------------------------------------------------------------

[
  { name: "Pawnee Hardware",       address: "1234 SE Some Ave., Pawnee, OR 12345" },
  { name: "Parks Department",      address: "2345 NE Some St., Pawnee, OR 12345" },
  { name: "Waffle House",          address: "3456 Some Bay., Pawnee, OR 12345" },
  { name: "Eagleton Country Club", address: "4567 Some Blvd., Eagleton, OR 12345" }
].each do |donation_option|
  DonationSite.find_or_create_by!(name: donation_option[:name]) do |donation|
    donation.address = donation_option[:address]
    donation.organization = pdx_org
  end
end

# ----------------------------------------------------------------------------
# Partners & Associated Data
# ----------------------------------------------------------------------------

partner_status_map = {
  pending: "pending",
  recertification_required: "recertification_required",
  approved: "verified",
  verified: "verified"
}

note = [
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent ac enim orci. Donec id consequat est. Vivamus luctus vel erat quis tincidunt. Nunc quis varius justo. Integer quam augue, dictum vitae bibendum in, fermentum quis felis. Nam euismod ultrices velit a tristique. Vestibulum sed tincidunt erat. Vestibulum et ullamcorper sem. Sed ante leo, molestie vitae augue ac, aliquam ultrices enim."
]

[
  {
    name: "Pawnee Parent Service",
    email: "verified@example.com",
    status: :approved,
    notes: note.sample
  },
  {
    name: "Pawnee Homeless Shelter",
    email: "invited@pawneehomelss.com",
    status: :invited,
    notes: note.sample
  },
  {
    name: "Pawnee Pregnancy Center",
    email: "unverified@pawneepregnancy.com",
    status: :invited,
    notes: note.sample
  },
  {
    name: "Pawnee Senior Citizens Center",
    email: "recertification_required@example.com",
    status: :recertification_required,
    notes: note.sample
  }
].each do |partner_option|
  p = Partner.find_or_create_by!(partner_option) do |partner|
    partner.organization = pdx_org
  end

  # ----------------------------------------------------------------------------
  # Creating associated records within the Partnerbase database
  #
  # **We have two seperate database. One for diaperbase and the other for partnerbase**
  # ----------------------------------------------------------------------------

  partner = Partners::Partner.create!({
                                        name: p.name,
                                        address1: Faker::Address.street_address,
                                        address2: "",
                                        city: Faker::Address.city,
                                        state: Faker::Address.state_abbr,
                                        zip_code: Faker::Address.zip,
                                        website: Faker::Internet.domain_name,
                                        zips_served: Faker::Address.zip,
                                        diaper_bank_id: pdx_org.id,
                                        diaper_partner_id: p.id,
                                        executive_director_name: Faker::Name.name,
                                        executive_director_email: p.email,
                                        executive_director_phone: Faker::PhoneNumber.phone_number,
                                        program_contact_name: Faker::Name.name,
                                        program_contact_email: Faker::Internet.email,
                                        program_contact_phone: Faker::PhoneNumber.phone_number,
                                        program_contact_mobile: Faker::PhoneNumber.phone_number,
                                        pick_up_name: Faker::Name.name,
                                        pick_up_email: Faker::Internet.email,
                                        pick_up_phone: Faker::PhoneNumber.phone_number,
                                        partner_status: partner_status_map[partner_option[:status]] || "pending",
                                        status_in_diaper_base: partner_option[:status]
                                      })

  Partners::User.create!(
    name: Faker::Name.name,
    password: "password",
    password_confirmation: "password",
    email: p.email,
    partner: partner
  )

  #
  # Skip creating records that they would have created after
  # they've accepted the invitation
  #
  next if partner.partner_status == 'pending'

  families = (1..Faker::Number.within(range: 4..13)).to_a.map do
    Partners::Family.create!(
      guardian_first_name: Faker::Name.first_name,
      guardian_last_name: Faker::Name.last_name,
      guardian_zip_code: Faker::Address.zip_code,
      guardian_country: "United States",
      guardian_phone: Faker::PhoneNumber.phone_number,
      agency_guardian_id: Faker::Name.name,
      home_adult_count: [1, 2, 3].sample,
      home_child_count: [0, 1, 2, 3, 4, 5].sample,
      home_young_child_count: [1, 2, 3, 4].sample,
      sources_of_income: Partners::Family::INCOME_TYPES.sample(2),
      guardian_employed: Faker::Boolean.boolean,
      guardian_employment_type: Partners::Family::EMPLOYMENT_TYPES.sample,
      guardian_monthly_pay: [1, 2, 3, 4].sample,
      guardian_health_insurance: Partners::Family::INSURANCE_TYPES.sample,
      comments: Faker::Lorem.paragraph,
      military: false,
      partner: partner
    )
  end

  families.each do |family|
    Partners::AuthorizedFamilyMember.create!(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      date_of_birth: Faker::Date.birthday(min_age: 18, max_age: 100),
      gender: Faker::Gender.binary_type,
      comments: Faker::Lorem.paragraph,
      family: family
    )

    family.home_child_count.times do
      Partners::Child.create!(
        family: family,
        first_name: Faker::Name.first_name,
        last_name: family.guardian_last_name,
        date_of_birth: Faker::Date.birthday(min_age: 5, max_age: 18),
        gender: Faker::Gender.binary_type,
        child_lives_with: Partners::Child::CAN_LIVE_WITH.sample(2),
        race: Partners::Child::RACES.sample,
        agency_child_id: family.agency_guardian_id,
        health_insurance: family.guardian_health_insurance,
        comments: Faker::Lorem.paragraph,
        active: Faker::Boolean.boolean,
        archived: false,
        item_needed_diaperid: partner.organization.item_id_to_display_string_map.key(Partners::Child::CHILD_ITEMS.sample)
      )
    end

    family.home_young_child_count.times do
      Partners::Child.create!(
        family: family,
        first_name: Faker::Name.first_name,
        last_name: family.guardian_last_name,
        date_of_birth: Faker::Date.birthday(min_age: 0, max_age: 5),
        gender: Faker::Gender.binary_type,
        child_lives_with: Partners::Child::CAN_LIVE_WITH.sample(2),
        race: Partners::Child::RACES.sample,
        agency_child_id: family.agency_guardian_id,
        health_insurance: family.guardian_health_insurance,
        comments: Faker::Lorem.paragraph,
        active: Faker::Boolean.boolean,
        archived: false,
        item_needed_diaperid: partner.organization.item_id_to_display_string_map.key(Partners::Child::CHILD_ITEMS.sample)
      )
    end
  end

  Faker::Number.within(range: 32..56).times do
    pr = Partners::Request.new(
      comments: Faker::Lorem.paragraph,
      partner: partner,
      for_families: Faker::Boolean.boolean
    )

    # Ensure that the item requests are valid with
    # the valid `item_id
    item_requests = Array.new(Faker::Number.within(range: 5..15)) do
      item = Item.all.sample

      Partners::ItemRequest.new(
        name: Partners::Child::CHILD_ITEMS.sample,
        quantity: Faker::Number.within(range: 10..30),
        partner_key: item.partner_key,
        item_id: item.id
      )
    end

    pr.item_requests = item_requests
    pr.save!
  end
end

# ----------------------------------------------------------------------------
# Storage Locations
# ----------------------------------------------------------------------------

inv_arbor = StorageLocation.find_or_create_by!(name: "Bulk Storage Location") do |inventory|
  inventory.address = "Unknown"
  inventory.organization = pdx_org
  inventory.warehouse_type = StorageLocation::WAREHOUSE_TYPES[0]
  inventory.square_footage = 10_000
end
inv_pdxdb = StorageLocation.find_or_create_by!(name: "Pawnee Main Bank (Office)") do |inventory|
  inventory.address = "Unknown"
  inventory.organization = pdx_org
  inventory.warehouse_type = StorageLocation::WAREHOUSE_TYPES[1]
  inventory.square_footage = 20_000
end

#
# Define all the InventoryItem for each of the StorageLocation
#
StorageLocation.all.each do |sl|
  sl.organization.items.each do |item|
    InventoryItem.create!(
      storage_location: sl,
      item: item,
      quantity: Faker::Number.within(range: 500..2000)
    )
  end
end

# ----------------------------------------------------------------------------
# Diaper Drives
# ----------------------------------------------------------------------------

[
  {
    name: 'Pamper the Poopsies',
    start_date: Time.current,
    organization: pdx_org
  }
].each { |drive| DiaperDrive.create! drive }

# ----------------------------------------------------------------------------
# Diaper Drive Participants
# ----------------------------------------------------------------------------

[
  { business_name: "A Good Place to Collect Diapers",
    contact_name: "fred",
    email: "good@place.is",
    organization: pdx_org },
  { business_name: "A Mediocre Place to Collect Diapers",
    contact_name: "wilma",
    email: "ok@place.is",
    organization: pdx_org }
].each { |participant| DiaperDriveParticipant.create! participant }

# ----------------------------------------------------------------------------
# Diaper Drives
# ----------------------------------------------------------------------------

[
  { name: "First Diaper Drive",
    start_date: 3.years.ago,
    end_date: 3.years.ago,
    organization: sf_org },
  { name: "Best Diaper Drive",
    start_date: 3.weeks.ago,
    end_date: 2.weeks.ago,
    organization: sf_org },
  { name: "Second Best Diaper Drive",
    start_date: 2.weeks.ago,
    end_date: 1.week.ago,
    organization: pdx_org }
].each { |diaper_drive| DiaperDrive.find_or_create_by! diaper_drive }

# ----------------------------------------------------------------------------
# Manufacturers
# ----------------------------------------------------------------------------

[
  { name: "Manufacturer 1", organization: pdx_org },
  { name: "Manufacturer 2", organization: pdx_org }
].each { |manu| Manufacturer.find_or_create_by! manu }

# ----------------------------------------------------------------------------
# Line Items
# ----------------------------------------------------------------------------

def seed_quantity(item_name, organization, storage_location, quantity)
  return if quantity.zero?

  item = Item.find_by(name: item_name, organization: organization)

  adjustment = organization.adjustments.create!(
    comment: "Starting inventory",
    storage_location: storage_location,
    user: organization.users.find_by(organization_admin: true)
  )

  LineItem.create!(quantity: quantity, item: item, itemizable: adjustment)

  adjustment.reload
  increasing_adjustment, decreasing_adjustment = adjustment.split_difference
  adjustment.storage_location.increase_inventory increasing_adjustment
  adjustment.storage_location.decrease_inventory decreasing_adjustment
end

items_by_category.each do |_category, entries|
  entries.each do |entry|
    seed_quantity(entry['name'], pdx_org, inv_arbor, entry['qty']['arbor'])
    seed_quantity(entry['name'], pdx_org, inv_pdxdb, entry['qty']['pdxdb'])
  end
end

# ----------------------------------------------------------------------------
# Barcode Items
# ----------------------------------------------------------------------------

[
  { value: "10037867880046", name: "Kids (Size 5)",         quantity: 108 },
  { value: "10037867880053", name: "Kids (Size 6)",         quantity: 92 },
  { value: "10037867880039", name: "Kids (Size 4)",         quantity: 124 },
  { value: "803516626364",   name: "Kids (Size 1)",         quantity: 40 },
  { value: "036000406535",   name: "Kids (Size 1)",         quantity: 44 },
  { value: "037000863427",   name: "Kids (Size 1)",         quantity: 35 },
  { value: "041260379000",   name: "Kids (Size 3)",         quantity: 160 },
  { value: "074887711700",   name: "Wipes (Baby)",          quantity: 8 },
  { value: "036000451306",   name: "Kids Pull-Ups (4T-5T)", quantity: 56 },
  { value: "037000862246",   name: "Kids (Size 4)",         quantity: 92 },
  { value: "041260370236",   name: "Kids (Size 4)",         quantity: 68 },
  { value: "036000407679",   name: "Kids (Size 4)",         quantity: 24 },
  { value: "311917152226",   name: "Kids (Size 4)",         quantity: 82 },
].each do |item|
  BarcodeItem.find_or_create_by!(value: item[:value]) do |barcode|
    barcode.item = pdx_org.items.find_by(name: item[:name])
    barcode.quantity = item[:quantity]
    barcode.organization = pdx_org
  end
end

# ----------------------------------------------------------------------------
# Donations
# ----------------------------------------------------------------------------

# Make some donations of all sorts
20.times.each do
  source = Donation::SOURCES.values.sample
  # Depending on which source it uses, additional data may need to be provided.
  donation = case source
             when Donation::SOURCES[:diaper_drive]
               Donation.create! source: source,
                                diaper_drive: DiaperDrive.first,
                                diaper_drive_participant: random_record_for_org(pdx_org, DiaperDriveParticipant),
                                storage_location: random_record_for_org(pdx_org, StorageLocation),
                                organization: pdx_org,
                                issued_at: Time.zone.now
             when Donation::SOURCES[:donation_site]
               Donation.create! source: source,
                                donation_site: random_record_for_org(pdx_org, DonationSite),
                                storage_location: random_record_for_org(pdx_org, StorageLocation),
                                organization: pdx_org,
                                issued_at: Time.zone.now
             when Donation::SOURCES[:manufacturer]
               Donation.create! source: source,
                                manufacturer: random_record_for_org(pdx_org, Manufacturer),
                                storage_location: random_record_for_org(pdx_org, StorageLocation),
                                organization: pdx_org,
                                issued_at: Time.zone.now
             else
               Donation.create! source: source,
                                storage_location: random_record_for_org(pdx_org, StorageLocation),
                                organization: pdx_org,
                                issued_at: Time.zone.now
             end

  rand(1..5).times.each do
    LineItem.create! quantity: rand(250..500), item: random_record_for_org(pdx_org, Item), itemizable: donation
  end
  donation.reload
  donation.storage_location.increase_inventory(donation)
end

# ----------------------------------------------------------------------------
# Distributions
# ----------------------------------------------------------------------------

# Make some distributions, but don't use up all the inventory
20.times.each do
  storage_location = random_record_for_org(pdx_org, StorageLocation)
  stored_inventory_items_sample = storage_location.inventory_items.sample(20)
  distribution = Distribution.create!(storage_location: storage_location,
                                      partner: random_record_for_org(pdx_org, Partner),
                                      organization: pdx_org,
                                      issued_at: Faker::Date.between(from: 4.days.ago, to: Time.zone.today),
                                      delivery_method: Distribution.delivery_methods.keys.sample,
                                      comment: 'Urgent')

  stored_inventory_items_sample.each do |stored_inventory_item|
    distribution_qty = rand(stored_inventory_item.quantity / 2)
    LineItem.create! quantity: distribution_qty, item: stored_inventory_item.item, itemizable: distribution if distribution_qty >= 1
  end
  distribution.reload
  distribution.storage_location.decrease_inventory(distribution)
end

# ----------------------------------------------------------------------------
# Requests
# ----------------------------------------------------------------------------

20.times.each do |count|
  status = count > 15 ? 'fulfilled' : 'pending'

  org_items = pdx_org.items.pluck(:id)
  request_items = Array.new(Faker::Number.within(range: 3..8)).map do |_item|
    {
      "item_id" => org_items.sample,
      "quantity" => Faker::Number.within(range: 5..10)
    }
  end

  Request.create(
    partner: random_record_for_org(pdx_org, Partner),
    organization: pdx_org,
    request_items: request_items,
    comments: "Urgent",
    status: status
  )
end

# ----------------------------------------------------------------------------
# Vendors
# ----------------------------------------------------------------------------

# Create some Vendors so Purchases can have vendor_ids
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
    created_at: (Time.zone.today - rand(15).days),
    updated_at: (Time.zone.today - rand(15).days),
  )
end

# ----------------------------------------------------------------------------
# Purchases
# ----------------------------------------------------------------------------

suppliers = %w(Target Wegmans Walmart Walgreens)
comments = [
  "Maecenas ante lectus, vestibulum pellentesque arcu sed, eleifend lacinia elit. Cras accumsan varius nisl, a commodo ligula consequat nec. Aliquam tincidunt diam id placerat rutrum.",
  "Integer a molestie tortor. Duis pretium urna eget congue porta. Fusce aliquet dolor quis viverra volutpat.",
  "Nullam dictum ac lectus at scelerisque. Phasellus volutpat, sem at eleifend tristique, massa mi cursus dui, eget pharetra ligula arcu sit amet nunc."
]

20.times do
  storage_location = random_record_for_org(pdx_org, StorageLocation)
  vendor = random_record_for_org(pdx_org, Vendor)
  Purchase.create(
    purchased_from: suppliers.sample,
    comment: comments.sample,
    organization_id: pdx_org.id,
    storage_location_id: storage_location.id,
    amount_spent_in_cents: rand(200..10_000),
    issued_at: (Time.zone.today - rand(15).days),
    created_at: (Time.zone.today - rand(15).days),
    updated_at: (Time.zone.today - rand(15).days),
    vendor_id: vendor.id
  )
end

# ----------------------------------------------------------------------------
# Flipper
# ----------------------------------------------------------------------------

Flipper::Adapters::ActiveRecord::Feature.find_or_create_by(key: "new_logo")

# ----------------------------------------------------------------------------
# Account Requests
# ----------------------------------------------------------------------------
# Add some Account Requests to fill up the account requests admin page

[{ organization_name: "Telluride Diaper Bank",    website: "TDB.com", confirmed_at: nil },
 { organization_name: "Ouray Diaper Bank",        website: "ODB.com",   confirmed_at: nil },
 { organization_name: "Canon City Diaper Bank",   website: "CCDB.com",  confirmed_at: nil },
 { organization_name: "Golden Diaper Bank",       website: "GDB.com",   confirmed_at: (Time.zone.today - rand(15).days) },
 { organization_name: "Westminster Diaper Bank",  website: "WDB.com",   confirmed_at: (Time.zone.today - rand(15).days) },
 { organization_name: "Lakewood Diaper Bank",     website: "LDB.com",   confirmed_at: (Time.zone.today - rand(15).days) }].each do |account_request|
  AccountRequest.create(
    name: Faker::Name.unique.name,
    email: Faker::Internet.unique.email,
    organization_name: account_request[:organization_name],
    organization_website: account_request[:website],
    request_details: Faker::Lorem.paragraphs.join(", "),
    confirmed_at: account_request[:confirmed_at]
  )
end
