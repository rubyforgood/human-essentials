# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# Creates Seed Data for the organization
DropoffLocation.find_or_create_by!(name: "Know Thy Food & Warehouse Cafe") do |location|
  location.address = "3434 SE Milwaukie Ave., Portland, OR 97202"
end
DropoffLocation.find_or_create_by!(name: "Tidee Didee Diaper Service") do |location|
  location.address = "6011 SE 92nd Ave., Portland,OR 97266"
end
DropoffLocation.find_or_create_by!(name: "Southside Swap & Play") do |location|
  location.address = "5239 SE Woodstock Ave, Portland, OR 97206"
end
DropoffLocation.find_or_create_by!(name: "Kuts 4 Kids & Adults") do |location|
  location.address = "4423 SE Hawthorne Blvd., Portland, OR 97215"
end
DropoffLocation.find_or_create_by!(name: "JJ Jump") do |location|
  location.address = "9057 SE Jannsen Rd., Clackamas, OR 97015"
end

Partner.find_or_create_by!(name: "Teen Parent Services - PPS", email: "someone@teenservices.org")
Partner.find_or_create_by!(name: "Portland Homeless Family Solutions", email: "anyone@portlandhomeless.com")
Partner.find_or_create_by!(name: "Pregnancy Resource Center", email: "contactus@pregnancyresources.com")
Partner.find_or_create_by!(name: "Rose Haven", email: "contact@rosehaven.com")
Partner.find_or_create_by!(name: "Volunteers of America", email: "info@volunteersofamerica.org")
Partner.find_or_create_by!(name: "Clackamas Service Center", email: "outreach@clackamas.com")
Partner.find_or_create_by!(name: "Housing Alternatives", email: "support@housingalternatives.com")
Partner.find_or_create_by!(name: "JOIN", email: "info@join.org")
Partner.find_or_create_by!(name: "Emmanuel Housing Center", email: "contact@emmanuelhousingcenter.com")
Partner.find_or_create_by!(name: "Catholic Charities", email: "contactus@catholiccharities.org")
Partner.find_or_create_by!(name: "Healthy Families of Oregon", email: "info@oregonfamilies.org")
Partner.find_or_create_by!(name: "NARA Northwest", email: "contactus@naranorthwest.org")
Partner.find_or_create_by!(name: "Job Corps", email: "someone@jobcorps.org")
Partner.find_or_create_by!(name: "Helensview Middle and High School", email: "programs@helensviewschooldistrict.edu")

inv_arbor = Inventory.find_or_create_by!(name: "Bulk Storage (Arborscape)") do |inventory|
  inventory.address = "Unknown"
end
inv_dsu = Inventory.find_or_create_by!(name: "Diaper Storage Unit") do |inventory|
  inventory.address = "Unknown"
end
inv_pdxdb = Inventory.find_or_create_by!(name: "PDX Diaper Bank (Office)") do |inventory|
  inventory.address = "Unknown"
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

def seed_quantity(item_id, inventory_id, quantity)
  return if (quantity == 0)
  InventoryItem.find_or_create_by(item_id: item_id, inventory_id: inventory_id) { |h|
    h.quantity = quantity
  }
end

items_by_category.each do |category, entries|
  entries.each do |entry|
    item = Item.find_or_create_by!(name: entry[:name])
    item.update_attributes(entry.except(:name).except(:qty).merge(category: category))

    seed_quantity(item.id, inv_arbor.id, entry[:qty][0])
    seed_quantity(item.id, inv_dsu.id, entry[:qty][1])
    seed_quantity(item.id, inv_pdxdb.id, entry[:qty][2])

  end
end
