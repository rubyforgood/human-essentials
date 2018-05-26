# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# Creates Seed Data for the organization

pdx_org = Organization.find_or_create_by!(short_name: "pdx_bank") do |organization|
  organization.name = "PDX Diaper Bank"
  organization.address = "P.O. Box 22613, Portland OR 97269"
  organization.street = "P.O. Box 22613"
  organization.city = "Portland"
  organization.state ="OR"
  organization.zipcode = "97269"
  organization.email = "info@pdxdiaperbank.org"
end

sf_org = Organization.find_or_create_by!(short_name: "sf_bank") do |organization|
  organization.name = "SF Diaper Bank"
  organization.address = "P.O. Box 12345, San Francisco CA 90210"
  organization.street = "P.O. Box 12345"
  organization.city = "San Francisco"
  organization.state ="CA"
  organization.zipcode = "90210"
  organization.email = "info@sfdiaperbank.org"
end

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

# qty is Arborscape, Diaper Storage Unit, PDX Diaperbank
items_by_category = {
  "Diapers - Adult Briefs" => [
    { name: "Adult Briefs (Large/X-Large)", qty: [0,0,3741] },
    { name: "Adult Briefs (Medium/Large)", qty: [0,0,108] },
    { name: "Adult Briefs (Small/Medium)", qty: [0,0,2742] },
    { name: "Adult Briefs (XXL)", qty: [0,0,24] }
  ],
  "Diapers - Childrens" => [
    { name: "Cloth Diapers (Plastic Cover Pants)", qty: [0,0,75] },
    { name: "Disposable Inserts", qty: [0,0,143] },
    { name: "Kids (Newborn)", qty: [0,0,4217] },
    { name: "Kids (Preemie)", qty: [0,240,360] },
    { name: "Kids (Size 1)", qty: [6051, 1870, 6742] },
    { name: "Kids (Size 2)", qty: [4480, 1380, 11082] },
    { name: "Kids (Size 3)", qty: [15080, 1776, 2596] },
    { name: "Kids (Size 4)", qty: [25472, 0, 3616] },
    { name: "Kids (Size 5)", qty: [13634, 0, 3616] },
    { name: "Kids (Size 6)", qty: [3216, 1, 211] },
    { name: "Kids L/XL (60-125 lbs)", qty: [0,49,0] },
    { name: "Kids Pull-Ups (2T-3T)", qty: [0,0,1532] },
    { name: "Kids Pull-Ups (3T-4T)", qty: [0,0,787] },
    { name: "Kids Pull-Ups (4T-5T)", qty: [0,408,124] },
    { name: "Kids S/M (38-65 lbs)", qty: [0,1495,264] },
    { name: "Swimmers", qty: [0,20,459] }
  ],
  "Diapers - Cloth (Adult)" => [
    { name: "Adult Cloth Diapers (Large/XL/XXL)", qty: [0,0,89] },
    { name: "Adult Cloth Diapers (Small/Medium)", qty: [0,0,2742] }
  ],
  "Diapers - Cloth (Kids)" => [
    { name: "Cloth Diapers (AIO's/Pocket)", qty: [0,0,219] },
    { name: "Cloth Diapers (Covers)", qty: [0,0,428] },
    { name: "Cloth Diapers (Prefolds & Fitted)", qty: [0,0,431] },
    { name: "Cloth Inserts (For Cloth Diapers)", qty: [0,0,0] },
    { name: "Cloth Swimmers (Kids)", qty: [0,0,0] }
  ],
  "Incontinence Pads - Adult" => [
    { name: "Adult Incontinence Pads", qty: [0,0,2304] },
    { name: "Underpads (Pack)", qty: [0,1,2] }
  ],
  "Misc Supplies" => [
    { name: "Bed Pads (Cloth)", qty: [0,0,44] },
    { name: "Bed Pads (Disposable)", qty: [0,0,0] },
    { name: "Bibs (Adult & Child)", qty: [0,0,35] },
    { name: "Diaper Rash Cream/Powder", qty: [0,0,0] },
  ],
  "Training Pants" => [
    { name: "Cloth Potty Training Pants/Underwear", qty: [0,0,246] },
  ],
  "Wipes - Childrens" => [
    { name: "Wipes (Baby)", qty: [0,0,162] },
  ]
}

def seed_quantity(item_id, storage_location_id, quantity)
  return if (quantity == 0)
  InventoryItem.find_or_create_by(item_id: item_id, storage_location_id: storage_location_id) { |h|
    h.quantity = quantity
  }
end

items_by_category.each do |category, entries|
  entries.each do |entry|
    item = Item.find_or_create_by!(name: entry[:name], organization: pdx_org)
    item.update_attributes(entry.except(:name).except(:qty).merge(category: category))

    seed_quantity(item.id, inv_arbor.id, entry[:qty][0])
    seed_quantity(item.id, inv_dsu.id, entry[:qty][1])
    seed_quantity(item.id, inv_pdxdb.id, entry[:qty][2])
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
               Donation.create! source: source, diaper_drive_participant: random_record(DiaperDriveParticipant), storage_location: random_record(StorageLocation), organization: pdx_org
             when Donation::SOURCES[:donation_site]
               Donation.create! source: source, donation_site: random_record(DonationSite), storage_location: random_record(StorageLocation), organization: pdx_org
             else
               Donation.create! source: source, storage_location: random_record(StorageLocation), organization: pdx_org
             end

  rand(1..5).times.each do
    LineItem.create! quantity: rand(1..500), item: random_record(Item), itemizable: donation
  end
end

20.times.each do
  distribution = Distribution.create! storage_location: random_record(StorageLocation), partner: random_record(Partner), organization: pdx_org

  rand(1..5).times.each do
    LineItem.create! quantity: rand(1..500), item: random_record(Item), itemizable: distribution
  end
end
