# This file should contain all the record creation needed to seed the database with demo values.
# The data can then be loaded with `rails db:seed` (or along with the creation of the db with `rails db:setup`).

unless Rails.env.development?
  puts "Database seeding has been configured to work only in development mode."
  return
end


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
  org.items.where(value_in_cents: 0).limit(10).update_all(value_in_cents: 100)
end


# ----------------------------------------------------------------------------
# Users
# ----------------------------------------------------------------------------

[
  { email: 'superadmin@example.com', organization_admin: false,                        super_admin: true },
  { email: 'org_admin1@example.com', organization_admin: true,  organization: pdx_org },
  { email: 'org_admin2@example.com', organization_admin: true,  organization: sf_org },
  { email: 'user_1@example.com',     organization_admin: false, organization: pdx_org },
  { email: 'user_2@example.com',     organization_admin: false, organization: sf_org },
  { email: 'test@example.com',       organization_admin: false, organization: pdx_org, super_admin: true },
  { email: 'test2@example.com',      organization_admin: true,  organization: pdx_org }
].each do |user|
  User.create(
    email:                 user[:email],
    password:              'password',
    password_confirmation: 'password',
    organization_admin:    user[:organization_admin],
    super_admin:           user[:super_admin],
    organization:          user[:organization]
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
# Partners
# ----------------------------------------------------------------------------

[
  { name: "Pawnee Parent Service",         email: "someone@pawneeparent.org",      status: :approved },
  { name: "Pawnee Homeless Shelter",       email: "anyone@pawneehomelss.com",      status: :invited },
  { name: "Pawnee Pregnancy Center",       email: "contactus@pawneepregnancy.com", status: :invited },
  { name: "Pawnee Senior Citizens Center", email: "help@pscc.org",                 status: :recertification_required }
].each do |partner_option|
  Partner.find_or_create_by!(partner_option) do |partner|
    partner.organization = pdx_org
  end
end


# ----------------------------------------------------------------------------
# Storage Locations
# ----------------------------------------------------------------------------

inv_arbor = StorageLocation.find_or_create_by!(name: "Bulk Storage Location") do |inventory|
  inventory.address = "Unknown"
  inventory.organization = pdx_org
end
inv_pdxdb = StorageLocation.find_or_create_by!(name: "Pawnee Main Bank (Office)") do |inventory|
  inventory.address = "Unknown"
  inventory.organization = pdx_org
end


# ----------------------------------------------------------------------------
# Diaper Drive Participants
# ----------------------------------------------------------------------------

[
  { business_name: "A Good Place to Collect Diapers",
    contact_name:  "fred",
    email:         "good@place.is",
    organization:  pdx_org },
  { business_name: "A Mediocre Place to Collect Diapers",
    contact_name:  "wilma",
    email:         "ok@place.is",
    organization:  pdx_org }
].each { |participant| DiaperDriveParticipant.create! participant }


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
  return if quantity == 0

  item = Item.find_by(name: item_name, organization: organization)

  adjustment = organization.adjustments.create!(
    comment:          "Starting inventory",
    storage_location: storage_location,
    user:             organization.users.find_by(organization_admin: true)
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
    barcode.item = Item.find_by(name: item[:name])
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
               Donation.create! source:                   source,
                                diaper_drive_participant: random_record_for_org(pdx_org, DiaperDriveParticipant),
                                storage_location:         random_record_for_org(pdx_org, StorageLocation),
                                organization:             pdx_org,
                                issued_at:                Time.zone.now
             when Donation::SOURCES[:donation_site]
               Donation.create! source:           source,
                                donation_site:    random_record_for_org(pdx_org, DonationSite),
                                storage_location: random_record_for_org(pdx_org, StorageLocation),
                                organization:     pdx_org,
                                issued_at:        Time.zone.now
             when Donation::SOURCES[:manufacturer]
               Donation.create! source:           source,
                                manufacturer:     random_record_for_org(pdx_org, Manufacturer),
                                storage_location: random_record_for_org(pdx_org, StorageLocation),
                                organization:     pdx_org,
                                issued_at:        Time.zone.now
             else
               Donation.create! source:           source,
                                storage_location: random_record_for_org(pdx_org, StorageLocation),
                                organization:     pdx_org,
                                issued_at:        Time.zone.now
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
                                      partner:          random_record_for_org(pdx_org, Partner),
                                      organization:     pdx_org,
                                      issued_at:        Faker::Date.between(from: 4.days.ago, to: Time.zone.today))

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
  Request.create(
    partner: random_record_for_org(pdx_org, Partner),
    organization: pdx_org,
    request_items: [{ "item_id" => Item.all.pluck(:id).sample, "quantity" => 3 },
                    { "item_id" => Item.all.pluck(:id).sample, "quantity" => 2 }],
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
    contact_name:    Faker::FunnyName.two_word_name,
    email:           Faker::Internet.email,
    phone:           Faker::PhoneNumber.cell_phone,
    comment:         Faker::Lorem.paragraph(sentence_count: 2),
    organization_id: Organization.all.pluck(:id).sample,
    address:         "#{Faker::Address.street_address} #{Faker::Address.city}, #{Faker::Address.state_abbr} #{Faker::Address.zip_code}",
    business_name:   Faker::Company.name,
    latitude:        rand(-90.000000000...90.000000000),
    longitude:       rand(-180.000000000...180.000000000),
    created_at:      (Date.today - rand(15).days),
    updated_at:      (Date.today - rand(15).days),
  )
end


# ----------------------------------------------------------------------------
# Purchases
# ----------------------------------------------------------------------------

suppliers = ["Target", "Wegmans", "Walmart", "Walgreens"]
comments = [
  "Maecenas ante lectus, vestibulum pellentesque arcu sed, eleifend lacinia elit. Cras accumsan varius nisl, a commodo ligula consequat nec. Aliquam tincidunt diam id placerat rutrum.",
  "Integer a molestie tortor. Duis pretium urna eget congue porta. Fusce aliquet dolor quis viverra volutpat.",
  "Nullam dictum ac lectus at scelerisque. Phasellus volutpat, sem at eleifend tristique, massa mi cursus dui, eget pharetra ligula arcu sit amet nunc."]

20.times do
  storage_location = random_record_for_org(pdx_org, StorageLocation)
  vendor = random_record_for_org(pdx_org, Vendor)
  Purchase.create(
    purchased_from:        suppliers.sample,
    comment:               comments.sample,
    organization_id:       pdx_org.id,
    storage_location_id:   storage_location.id,
    amount_spent_in_cents: rand(200..10000),
    issued_at:             (Date.today - rand(15).days),
    created_at:            (Date.today - rand(15).days),
    updated_at:            (Date.today - rand(15).days),
    vendor_id:             vendor.id
  )
end

# ----------------------------------------------------------------------------
# Flipper
# ----------------------------------------------------------------------------

Flipper::Adapters::ActiveRecord::Feature.find_or_create_by(key: "new_logo")
