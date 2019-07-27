# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# Creates Seed Data for the organization

def random_record(klass)
  # FIXME: This produces a deprecation warning. Could replace it with: .order(Arel.sql('random()'))
  klass.limit(1).order("random()").first
end

# Initial starting qty for our test organizations
base_items = File.read(Rails.root.join("db", "base_items.json"))
items_by_category = JSON.parse(base_items)

# Creates the Base Items
items_by_category.each do |category, entries|
  entries.each do |entry|
    BaseItem.find_or_create_by!(name: entry["name"], category: category, partner_key: entry["key"])
  end
end

pdx_org = Organization.find_or_create_by!(short_name: "diaper_bank") do |organization|
  organization.name = "Pawnee Diaper Bank"
  organization.street = "P.O. Box 22613"
  organization.city = "Pawnee"
  organization.state = "Indiana"
  organization.zipcode = "12345"
  organization.email = "info@pawneediaper.org"
end
Organization.seed_items(pdx_org)

sf_org = Organization.find_or_create_by!(short_name: "sf_bank") do |organization|
  organization.name = "SF Diaper Bank"
  organization.street = "P.O. Box 12345"
  organization.city = "San Francisco"
  organization.state = "CA"
  organization.zipcode = "90210"
  organization.email = "info@sfdiaperbank.org"
end
Organization.seed_items(sf_org)

# super admin
user = User.create email: 'superadmin@example.com', password: 'password', password_confirmation: 'password', organization_admin: false, super_admin: true

# org admins
user = User.create email: 'org_admin1@example.com', password: 'password', password_confirmation: 'password', organization: pdx_org, organization_admin: true
user2 = User.create email: 'org_admin2@example.com', password: 'password', password_confirmation: 'password', organization: sf_org, organization_admin: true

# regular users
User.create email: 'user_1@example.com', password: 'password', password_confirmation: 'password', organization: pdx_org, organization_admin: false
User.create email: 'user_2@example.com', password: 'password', password_confirmation: 'password', organization: sf_org, organization_admin: false

# test users
User.create email: 'test@example.com', password: 'password', password_confirmation: 'password', organization: pdx_org, organization_admin: false, super_admin: true
User.create email: 'test2@example.com', password: 'password', password_confirmation: 'password', organization: sf_org, organization_admin: true

DonationSite.find_or_create_by!(name: "Pawnee Hardware") do |location|
  location.address = "1234 SE Some Ave., Pawnee, OR 12345"
  location.organization = pdx_org
end
DonationSite.find_or_create_by!(name: "Parks Department") do |location|
  location.address = "2345 NE Some St., Pawnee, OR 12345"
  location.organization = pdx_org
end
DonationSite.find_or_create_by!(name: "Waffle House") do |location|
  location.address = "3456 Some Bay., Pawnee, OR 12345"
  location.organization = pdx_org
end
DonationSite.find_or_create_by!(name: "Eagleton Country Club") do |location|
  location.address = "4567 Some Blvd., Pawnee, OR 12345"
  location.organization = pdx_org
end

Partner.find_or_create_by!(name: "Pawnee Parent Service", email: "someone@pawneeparent.org", status: :approved) do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Pawnee Homeless Shelter", email: "anyone@pawneehomelss.com", status: :invited) do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Pawnee Pregnancy Center", email: "contactus@pawneepregnancy.com", status: :invited) do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Pawnee Family Center", email: "families@pawneefamilies.org", status: :uninvited) do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Pawnee Senior Citizens Center", email: "help@pscc.org", status: :recertification_required) do |partner|
  partner.organization = pdx_org
end

inv_arbor = StorageLocation.find_or_create_by!(name: "Bulk Storage Location") do |inventory|
  inventory.address = "Unknown"
  inventory.organization = pdx_org
end
inv_pdxdb = StorageLocation.find_or_create_by!(name: "Pawnee Main Bank (Office)") do |inventory|
  inventory.address = "Unknown"
  inventory.organization = pdx_org
end

DiaperDriveParticipant.create! business_name: "A Good Place to Collect Diapers",
                               contact_name: "fred",
                               email: "good@place.is",
                               organization: pdx_org
DiaperDriveParticipant.create! business_name: "A Mediocre Place to Collect Diapers",
                               contact_name: "wilma",
                               email: "ok@place.is",
                               organization: pdx_org

Manufacturer.find_or_create_by! name: "Manufacturer 1",
                                organization: pdx_org
Manufacturer.find_or_create_by! name: "Manufacturer 2",
                                organization: pdx_org

def seed_quantity(item_name, organization, storage_location, quantity)
  return if quantity == 0

  item = Item.find_by(name: item_name, organization: organization)

  adjustment = organization.adjustments.create!(
    comment: "Starting inventory",
    storage_location: storage_location
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

BarcodeItem.find_or_create_by!(value: "10037867880046") do |barcode|
  barcode.item = Item.find_by(name: "Kids (Size 5)")
  barcode.quantity = 108
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "10037867880053") do |barcode|
  barcode.item = Item.find_by(name: "Kids (Size 6)")
  barcode.quantity = 92
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "10037867880039") do |barcode|
  barcode.item = Item.find_by(name: "Kids (Size 4)")
  barcode.quantity = 124
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "803516626364") do |barcode|
  barcode.item = Item.find_by(name: "Kids (Size 1)")
  barcode.quantity = 40
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "036000406535") do |barcode|
  barcode.item = Item.find_by(name: "Kids (Size 1)")
  barcode.quantity = 44
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "037000863427") do |barcode|
  barcode.item = Item.find_by(name: "Kids (Size 1)")
  barcode.quantity = 35
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "041260379000") do |barcode|
  barcode.item = Item.find_by(name: "Kids (Size 3)")
  barcode.quantity = 160
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "074887711700") do |barcode|
  barcode.item = Item.find_by(name: "Wipes (Baby)")
  barcode.quantity = 8
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "036000451306") do |barcode|
  barcode.item = Item.find_by(name: "Kids Pull-Ups (4T-5T)")
  barcode.quantity = 56
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "037000862246") do |barcode|
  barcode.item = Item.find_by(name: "Kids (Size 4)")
  barcode.quantity = 92
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "041260370236") do |barcode|
  barcode.item = Item.find_by(name: "Kids (Size 4)")
  barcode.quantity = 68
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "036000407679") do |barcode|
  barcode.item = Item.find_by(name: "Kids (Size 4)")
  barcode.quantity = 24
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "311917152226") do |barcode|
  barcode.item = Item.find_by(name: "Kids (Size 4)")
  barcode.quantity = 82
  barcode.organization = pdx_org
end

# Make some donations of all sorts
20.times.each do
  source = Donation::SOURCES.values.sample
  # Depending on which source it uses, additional data may need to be provided.
  donation = case source
             when Donation::SOURCES[:diaper_drive]
               Donation.create! source: source, diaper_drive_participant: random_record(DiaperDriveParticipant), storage_location: random_record(StorageLocation), organization: pdx_org, issued_at: Time.zone.now
             when Donation::SOURCES[:donation_site]
               Donation.create! source: source, donation_site: random_record(DonationSite), storage_location: random_record(StorageLocation), organization: pdx_org, issued_at: Time.zone.now
             when Donation::SOURCES[:manufacturer]
               Donation.create! source: source, manufacturer: random_record(Manufacturer), storage_location: random_record(StorageLocation), organization: pdx_org, issued_at: Time.zone.now
             else
               Donation.create! source: source, storage_location: random_record(StorageLocation), organization: pdx_org, issued_at: Time.zone.now
             end

  rand(1..5).times.each do
    LineItem.create! quantity: rand(250..500), item: random_record(Item), itemizable: donation
  end
  donation.reload
  donation.storage_location.increase_inventory(donation)
end

# Make some distributions, but don't use up all the inventory
20.times.each do
  storage_location = random_record(StorageLocation)
  stored_inventory_items_sample = storage_location.inventory_items.sample(20)

  distribution = Distribution.create!(storage_location: storage_location,
                                      partner: random_record(Partner),
                                      organization: pdx_org,
                                      issued_at: (Date.today + rand(15).days))

  stored_inventory_items_sample.each do |stored_inventory_item|
    distribution_qty = rand(stored_inventory_item.quantity / 2)
    LineItem.create! quantity: distribution_qty, item: stored_inventory_item.item, itemizable: distribution if distribution_qty >= 1
  end
  distribution.reload
  distribution.storage_location.decrease_inventory(distribution)
end

20.times.each do |count|
  status = count > 15 ? 'fulfilled' : 'pending'
  Request.create(
    partner: random_record(Partner),
    organization: random_record(Organization),
    request_items: [{ "item_id" => Item.all.pluck(:id).sample, "quantity" => 3 },
                    { "item_id" => Item.all.pluck(:id).sample, "quantity" => 2 }],
    comments: "Urgent",
    status: status
  )
end

Flipper::Adapters::ActiveRecord::Feature.find_or_create_by(key: "new_logo")
