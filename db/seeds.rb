# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# Creates Seed Data for the organization

# qty is Arborscape, Diaper Storage Unit, PDX Diaperbank
canonical_items = File.read(Rails.root.join("db", "canonical_items.json"))
items_by_category = JSON.parse(canonical_items)

# Creates the Canonical Items
items_by_category.each do |category, entries|
  entries.each do |entry|
    CanonicalItem.find_or_create_by!(name: entry["name"], category: category)
  end
end

pdx_org = Organization.find_or_create_by!(short_name: "pdx_bank") do |organization|
  organization.name = "PDX Diaper Bank"
  organization.street = "P.O. Box 22613"
  organization.city = "Portland"
  organization.state ="OR"
  organization.zipcode = "97269"
  organization.email = "info@pdxdiaperbank.org"
end
Organization.seed_items(pdx_org)

sf_org = Organization.find_or_create_by!(short_name: "sf_bank") do |organization|
  organization.name = "SF Diaper Bank"
  organization.street = "P.O. Box 12345"
  organization.city = "San Francisco"
  organization.state ="CA"
  organization.zipcode = "90210"
  organization.email = "info@sfdiaperbank.org"
end
Organization.seed_items(sf_org)

user = User.create email: 'test@example.com', password: 'password', password_confirmation: 'password', organization: pdx_org, organization_admin: true
user2 = User.create email: 'test2@example.com', password: 'password', password_confirmation: 'password', organization: sf_org

DonationSite.find_or_create_by!(name: "Know Thy Food & Warehouse Cafe") do |location|
  location.address = "3434 SE Milwaukie Ave., Portland, OR 97202"
  location.organization = pdx_org
end
DonationSite.find_or_create_by!(name: "Tidee Didee Diaper Service") do |location|
  location.address = "6011 SE 92nd Ave., Portland,OR 97266"
  location.organization = pdx_org
end
DonationSite.find_or_create_by!(name: "Southside Swap & Play") do |location|
  location.address = "5239 SE Woodstock Ave, Portland, OR 97206"
  location.organization = pdx_org
end
DonationSite.find_or_create_by!(name: "Kuts 4 Kids & Adults") do |location|
  location.address = "4423 SE Hawthorne Blvd., Portland, OR 97215"
  location.organization = pdx_org
end
DonationSite.find_or_create_by!(name: "JJ Jump") do |location|
  location.address = "9057 SE Jannsen Rd., Clackamas, OR 97015"
  location.organization = pdx_org
end

Partner.find_or_create_by!(name: "Teen Parent Services - PPS", email: "someone@teenservices.org") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Portland Homeless Family Solutions", email: "anyone@portlandhomeless.com") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Pregnancy Resource Center", email: "contactus@pregnancyresources.com") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Rose Haven", email: "contact@rosehaven.com") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Volunteers of America", email: "info@volunteersofamerica.org") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Clackamas Service Center", email: "outreach@clackamas.com") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Housing Alternatives", email: "support@housingalternatives.com") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "JOIN", email: "info@join.org") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Emmanuel Housing Center", email: "contact@emmanuelhousingcenter.com") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Catholic Charities", email: "contactus@catholiccharities.org") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Healthy Families of Oregon", email: "info@oregonfamilies.org") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "NARA Northwest", email: "contactus@naranorthwest.org") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Job Corps", email: "someone@jobcorps.org") do |partner|
  partner.organization = pdx_org
end
Partner.find_or_create_by!(name: "Helensview Middle and High School", email: "programs@helensviewschooldistrict.edu") do |partner|
  partner.organization = pdx_org
end

inv_arbor = StorageLocation.find_or_create_by!(name: "Bulk Storage (Arborscape)") do |inventory|
  inventory.address = "Unknown"
  inventory.organization = pdx_org
end
inv_dsu = StorageLocation.find_or_create_by!(name: "Diaper Storage Unit") do |inventory|
  inventory.address = "Unknown"
  inventory.organization = pdx_org
end
inv_pdxdb = StorageLocation.find_or_create_by!(name: "PDX Diaper Bank (Office)") do |inventory|
  inventory.address = "Unknown"
  inventory.organization = pdx_org
end

def seed_quantity(item_name, organization_id, storage_location_id, quantity)
  return if (quantity == 0)
  item_id = Item.find_by(name: item_name, organization_id: organization_id).id
  InventoryItem.find_or_create_by(item_id: item_id, storage_location_id: storage_location_id) { |h|
    h.quantity = quantity
  }
end

# qty is Arborscape, Diaper Storage Unit, PDX Diaperbank
items_by_category.each do |_category, entries|
  entries.each do |entry|
    seed_quantity(entry['name'], pdx_org, inv_arbor.id, entry['qty'][0])
    seed_quantity(entry['name'], pdx_org, inv_dsu.id, entry['qty'][1])
    seed_quantity(entry['name'], pdx_org, inv_pdxdb.id, entry['qty'][2])
  end
end

BarcodeItem.find_or_create_by!(value: "10037867880046") do |barcode|
  barcode.item =  Item.find_by(name: "Kids (Size 5)")
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
  barcode.item =  Item.find_by(name: "Kids (Size 4)")
  barcode.quantity = 92
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "041260370236") do |barcode|
  barcode.item =  Item.find_by(name: "Kids (Size 4)")
  barcode.quantity = 68
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "036000407679") do |barcode|
  barcode.item =  Item.find_by(name: "Kids (Size 4)")
  barcode.quantity = 24
  barcode.organization = pdx_org
end
BarcodeItem.find_or_create_by!(value: "311917152226") do |barcode|
  barcode.item =  Item.find_by(name: "Kids (Size 4)")
  barcode.quantity = 82
  barcode.organization = pdx_org
end

DiaperDriveParticipant.create! name: "A Good Place to Collect Diapers", email: "good@place.is", organization: pdx_org
DiaperDriveParticipant.create! name: "A Mediocre Place to Collect Diapers", email: "ok@place.is", organization: pdx_org

def random_record(klass)
  klass.limit(1).order("random()").first
end

20.times.each do
  source = Donation::SOURCES.values.sample
  # Depending on which source it uses, additional data may need to be provided.
  donation = case source
             when Donation::SOURCES[:diaper_drive]
               Donation.create! source: source, diaper_drive_participant: random_record(DiaperDriveParticipant), storage_location: random_record(StorageLocation), organization: pdx_org, issued_at: Time.now
             when Donation::SOURCES[:donation_site]
               Donation.create! source: source, donation_site: random_record(DonationSite), storage_location: random_record(StorageLocation), organization: pdx_org, issued_at: Time.now
             else
               Donation.create! source: source, storage_location: random_record(StorageLocation), organization: pdx_org, issued_at: Time.now
             end

  rand(1..5).times.each do
    LineItem.create! quantity: rand(1..500), item: random_record(Item), itemizable: donation
  end
end

20.times.each do
  distribution = Distribution.create! storage_location: random_record(StorageLocation), partner: random_record(Partner), organization: pdx_org, issued_at: Time.now

  rand(1..5).times.each do
    LineItem.create! quantity: rand(1..500), item: random_record(Item), itemizable: distribution
  end
end

Flipper::Adapters::ActiveRecord::Feature.find_or_create_by(key: "new_logo")