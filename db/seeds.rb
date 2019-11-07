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
@items_by_category = JSON.parse(base_items)


# ----------------------------------------------------------------------------
# Base Items
# ----------------------------------------------------------------------------

@items_by_category.each do |category, entries|
  entries.each do |entry|
    BaseItem.find_or_create_by!(name: entry["name"], category: category, partner_key: entry["key"])
  end
end


# pdx_org will be populated with a minimal but complete set of data
pdx_org = Organization.find_or_create_by!(short_name: "diaper_bank") do |organization|
  organization.name    = "Pawnee Diaper Bank"
  organization.street  = "P.O. Box 22613"
  organization.city    = "Pawnee"
  organization.state   = "Indiana"
  organization.zipcode = "12345"
  organization.email   = "info@pawneediaper.org"
end
Organization.seed_items(pdx_org)

# sf_org will get only a minimal amount with which to start populating manually
sf_org = Organization.find_or_create_by!(short_name: "sf_bank") do |organization|
  organization.name    = "SF Diaper Bank"
  organization.street  = "P.O. Box 12345"
  organization.city    = "San Francisco"
  organization.state   = "CA"
  organization.zipcode = "90210"
  organization.email   = "info@sfdiaperbank.org"
end
Organization.seed_items(sf_org)


# This array contains organizations _other than_ sf_org that need to be seeded
# with minimal but complete sets of data. It default to only pdx but you can add others.
# If you add an organization, to this array, you will need to:
#   1) create it
#   2) add users to it in the Users section below
STANDARD_ORGS_TO_SEED = [pdx_org]

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
    { email: 'test2@example.com',      organization_admin: true,  organization: pdx_org },
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

def create_donation_sites(organization)
  [
    { name: "Pawnee Hardware",       address: "1234 SE Some Ave., Pawnee, OR 12345" },
    { name: "Parks Department",      address: "2345 NE Some St., Pawnee, OR 12345" },
    { name: "Waffle House",          address: "3456 Some Bay., Pawnee, OR 12345" },
    { name: "Eagleton Country Club", address: "4567 Some Blvd., Eagleton, OR 12345" }
  ].each do |donation_option|
    search_values = { name: donation_option[:name], organization: organization }
    DonationSite.find_or_create_by!(search_values) do |donation_site|
      donation_site.address = donation_option[:address]
      donation_site.organization = organization
    end
  end
end

STANDARD_ORGS_TO_SEED.each { |org| create_donation_sites(org) }


# ----------------------------------------------------------------------------
# Partners
# ----------------------------------------------------------------------------

def create_partners(organization)
  [
    { name: "Pawnee Parent Service",         email: "someone@pawneeparent.org",      status: :approved },
    { name: "Pawnee Homeless Shelter",       email: "anyone@pawneehomelss.com",      status: :invited },
    { name: "Pawnee Pregnancy Center",       email: "contactus@pawneepregnancy.com", status: :invited },
    { name: "Pawnee Senior Citizens Center", email: "help@pscc.org",                 status: :recertification_required }
  ].each do |search_values|
    search_values[:organization] = organization
    Partner.find_or_create_by!(search_values) do |partner|
      partner.organization = organization
    end
  end
end

STANDARD_ORGS_TO_SEED.each { |org| create_partners(org) }


# ----------------------------------------------------------------------------
# Storage Locations
# ----------------------------------------------------------------------------

def create_storage_locations(organization)
  @storage_locations ||= {}

  search_values = { name: "Bulk Storage Location", organization: organization }
  inv_arbor = StorageLocation.find_or_create_by!(search_values) do |inventory|
    inventory.address = "Unknown"
    inventory.organization = organization
  end

  search_values = { name: "Pawnee Main Bank (Office)", organization: organization }
  inv_pdxdb = StorageLocation.find_or_create_by!(search_values) do |inventory|
    inventory.address = "Unknown"
    inventory.organization = organization
  end

  @storage_locations[organization] = { arbor: inv_arbor, pdxdb: inv_pdxdb }
end

STANDARD_ORGS_TO_SEED.each { |org| create_storage_locations(org) }


# ----------------------------------------------------------------------------
# Diaper Drive Participants
# ----------------------------------------------------------------------------

def create_participants(organization)
  [
    { business_name: "A Good Place to Collect Diapers",
      contact_name:  "fred",
      email:         "good@place.is",
      organization:  organization },
    { business_name: "A Mediocre Place to Collect Diapers",
      contact_name:  "wilma",
      email:         "ok@place.is",
      organization:  organization }
  ].each { |participant| DiaperDriveParticipant.create! participant }
end

STANDARD_ORGS_TO_SEED.each { |org| create_participants(org) }



# ----------------------------------------------------------------------------
# Manufacturers
# ----------------------------------------------------------------------------

def create_manufacturers(organization)
  [
    { name: "Manufacturer 1", organization: organization },
    { name: "Manufacturer 2", organization: organization }
  ].each { |search_values| Manufacturer.find_or_create_by! search_values }
end

STANDARD_ORGS_TO_SEED.each { |org| create_manufacturers(org) }


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

def seed_item_quantities(organization)
  @items_by_category.each do |_category, entries|
    entries.each do |entry|
      seed_quantity(entry['name'], organization, @storage_locations[organization][:pdxdb], entry['qty']['pdxdb'])
      seed_quantity(entry['name'], organization, @storage_locations[organization][:arbor], entry['qty']['arbor'])
    end
  end
end

  STANDARD_ORGS_TO_SEED.each { |org| seed_item_quantities(org) }


# ----------------------------------------------------------------------------
# Barcode Items
# ----------------------------------------------------------------------------

def create_barcode_items(organization)
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
    search_values = { value: item[:value], organization: organization}
    BarcodeItem.find_or_create_by!(search_values) do |barcode|
      barcode.item = Item.find_by(name: item[:name])
      barcode.quantity = item[:quantity]
      barcode.organization = organization
    end
  end
end

STANDARD_ORGS_TO_SEED.each { |org| create_barcode_items(org) }



# ----------------------------------------------------------------------------
# Donations
# ----------------------------------------------------------------------------

def create_donations(organization)
  source = Donation::SOURCES.values.sample

  attrs = {
      source:                   source,
      storage_location:         random_record_for_org(organization, StorageLocation),
      organization:             organization,
      issued_at:                Time.zone.now,
  }

  # Depending on which source it uses, additional data may need to be provided.
  case source
  when Donation::SOURCES[:diaper_drive]
    attrs[:diaper_drive_participant] = random_record_for_org(organization, DiaperDriveParticipant)
  when Donation::SOURCES[:donation_site]
    attrs[:donation_site] = random_record_for_org(organization, DonationSite)
  when Donation::SOURCES[:manufacturer]
    attrs[:manufacturer] = random_record_for_org(organization, Manufacturer)
  end

  donation = Donation.create! attrs

  rand(1..5).times.each do
    LineItem.create! quantity: rand(250..500), item: random_record_for_org(organization, Item), itemizable: donation
  end
  donation.reload
  donation.storage_location.increase_inventory(donation)
end

STANDARD_ORGS_TO_SEED.each do |organization|
  20.times.each { create_donations(organization) }
end


# ----------------------------------------------------------------------------
# Distributions
# ----------------------------------------------------------------------------

def create_distributions(organization)
# Make some distributions, but don't use up all the inventory
  20.times.each do
    storage_location = random_record_for_org(organization, StorageLocation)
    stored_inventory_items_sample = storage_location.inventory_items.sample(20)

    distribution = Distribution.create!(storage_location: storage_location,
                                        partner:          random_record_for_org(organization, Partner),
                                        organization:     organization,
                                        issued_at:        Faker::Date.between(from: 4.days.ago, to: Time.zone.today))

    stored_inventory_items_sample.each do |stored_inventory_item|
      distribution_qty = rand(stored_inventory_item.quantity / 2)
      LineItem.create! quantity: distribution_qty, item: stored_inventory_item.item, itemizable: distribution if distribution_qty >= 1
    end
    distribution.reload
    distribution.storage_location.decrease_inventory(distribution)
  end
end

STANDARD_ORGS_TO_SEED.each { |org| create_distributions(org) }


# ----------------------------------------------------------------------------
# Requests
# ----------------------------------------------------------------------------

def create_requests(organization)
  20.times.each do |count|
    status = count > 15 ? 'fulfilled' : 'pending'
    Request.create(
      partner: random_record_for_org(organization, Partner),
      organization: organization,
      request_items: [{ "item_id" => Item.all.pluck(:id).sample, "quantity" => 3 },
                      { "item_id" => Item.all.pluck(:id).sample, "quantity" => 2 }],
      comments: "Urgent",
      status: status
    )
  end
end

STANDARD_ORGS_TO_SEED.each { |org| create_requests(org) }


# ----------------------------------------------------------------------------
# Vendors
# ----------------------------------------------------------------------------

def create_vendors(organization)
  # Create some Vendors so Purchases can have vendor_ids
  3.times do
    Vendor.create(
      contact_name:    Faker::FunnyName.two_word_name,
      email:           Faker::Internet.email,
      phone:           Faker::PhoneNumber.cell_phone,
      comment:         Faker::Lorem.paragraph(sentence_count: 2),
      organization_id: organization.id,
      address:         "#{Faker::Address.street_address} #{Faker::Address.city}, #{Faker::Address.state_abbr} #{Faker::Address.zip_code}",
      business_name:   Faker::Company.name,
      latitude:        rand(-90.000000000...90.000000000),
      longitude:       rand(-180.000000000...180.000000000),
      created_at:      (Date.today - rand(15).days),
      updated_at:      (Date.today - rand(15).days),
    )
  end
end

STANDARD_ORGS_TO_SEED.each { |org| create_vendors(org) }


# ----------------------------------------------------------------------------
# Purchases
# ----------------------------------------------------------------------------

def create_purchases(organization)
  suppliers = ["Target", "Wegmans", "Walmart", "Walgreens"]
  comments = [
    "Maecenas ante lectus, vestibulum pellentesque arcu sed, eleifend lacinia elit. Cras accumsan varius nisl, a commodo ligula consequat nec. Aliquam tincidunt diam id placerat rutrum.",
    "Integer a molestie tortor. Duis pretium urna eget congue porta. Fusce aliquet dolor quis viverra volutpat.",
    "Nullam dictum ac lectus at scelerisque. Phasellus volutpat, sem at eleifend tristique, massa mi cursus dui, eget pharetra ligula arcu sit amet nunc."]

  20.times do
    storage_location = random_record_for_org(organization, StorageLocation)
    vendor = random_record_for_org(organization, Vendor)
    Purchase.create(
      purchased_from:        suppliers.sample,
      comment:               comments.sample,
      organization_id:       organization.id,
      storage_location_id:   storage_location.id,
      amount_spent_in_cents: rand(200..10000),
      issued_at:             (Date.today - rand(15).days),
      created_at:            (Date.today - rand(15).days),
      updated_at:            (Date.today - rand(15).days),
      vendor_id:             vendor.id
    )
  end
end

STANDARD_ORGS_TO_SEED.each { |org| create_purchases(org) }


# ----------------------------------------------------------------------------
# Flipper
# ----------------------------------------------------------------------------

Flipper::Adapters::ActiveRecord::Feature.find_or_create_by(key: "new_logo")


