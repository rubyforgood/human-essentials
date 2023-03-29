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
# NDBN Members
# ----------------------------------------------------------------------------
#
NDBNMember.create!(ndbn_member_id: 10000, account_name: "Pawnee")
NDBNMember.create!(ndbn_member_id: 20000, account_name: "Other Spot")
NDBNMember.create!(ndbn_member_id: 30000, account_name: "Amazing Place")

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
  ['Diapers', 'Period Supplies', 'Adult Incontinence'].each do |letter|
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
# Partner Group & Item Categories
# ----------------------------------------------------------------------------
Organization.all.each do |org|
  # Setup the Partner Group & their item categories
  partner_group = FactoryBot.create(:partner_group, organization: org)

  total_item_categories_to_add = Faker::Number.between(from: 1, to: 2)
  org.item_categories.sample(total_item_categories_to_add).each do |item_category|
    partner_group.item_categories << item_category
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
].each do |user_data|
  user = User.create(
    email: user_data[:email],
    password: 'password!',
    password_confirmation: 'password!'
  )

  if user_data[:organization]
    user.add_role(:org_user, user_data[:organization])
  end

  if user_data[:organization_admin]
    user.add_role(:org_admin, user_data[:organization])
  end

  if user_data[:super_admin]
    user.add_role(:super_admin)
  end
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
    email: "invited@pawneehomeless.com",
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
    partner.partner_group = pdx_org.partner_groups.first
  end

  profile = Partners::Profile.create!({
                                        essentials_bank_id: p.organization_id,
                                        partner_id: p.id,
                                        address1: Faker::Address.street_address,
                                        address2: "",
                                        city: Faker::Address.city,
                                        state: Faker::Address.state_abbr,
                                        zip_code: Faker::Address.zip,
                                        website: Faker::Internet.domain_name,
                                        zips_served: Faker::Address.zip,
                                        executive_director_name: Faker::Name.name,
                                        executive_director_email: p.email,
                                        executive_director_phone: Faker::PhoneNumber.phone_number,
                                        primary_contact_name: Faker::Name.name,
                                        primary_contact_email: Faker::Internet.email,
                                        primary_contact_phone: Faker::PhoneNumber.phone_number,
                                        primary_contact_mobile: Faker::PhoneNumber.phone_number,
                                        pick_up_name: Faker::Name.name,
                                        pick_up_email: Faker::Internet.email,
                                        pick_up_phone: Faker::PhoneNumber.phone_number
                                      })

  user = ::User.create!(
    name: Faker::Name.name,
    password: "password!",
    password_confirmation: "password!",
    email: p.email,
    invitation_sent_at: Time.utc(2021, 9, 8, 12, 43, 4),
    last_sign_in_at: Time.utc(2021, 9, 9, 11, 34, 4)
  )

  user.add_role(:partner, p)

  user_2 = ::User.create!(
    name: Faker::Name.name,
    password: "password!",
    password_confirmation: "password!",
    email: Faker::Internet.email,
    invitation_sent_at: Time.utc(2021, 9, 16, 12, 43, 4),
    last_sign_in_at: Time.utc(2021, 9, 17, 11, 34, 4)
  )

  user_2.add_role(:partner, p)

  #
  # Skip creating records that they would have created after
  # they've accepted the invitation
  #
  next if p.status == 'uninvited'

  families = (1..Faker::Number.within(range: 4..13)).to_a.map do
    Partners::Family.create!(
      guardian_first_name: Faker::Name.first_name,
      guardian_last_name: Faker::Name.last_name,
      guardian_zip_code: Faker::Address.zip_code,
      guardian_county: Faker::Address.community, # Faker doesn't have county, this has same flavor, and isn't country
      guardian_phone: Faker::PhoneNumber.phone_number,
      case_manager: Faker::Name.name,
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
      partner: p
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
        first_name: family.guardian_first_name,
        last_name: family.guardian_last_name,
        date_of_birth: Faker::Date.birthday(min_age: 5, max_age: 18),
        gender: Faker::Gender.binary_type,
        child_lives_with: Partners::Child::CAN_LIVE_WITH.sample(2),
        race: Partners::Child::RACES.sample,
        agency_child_id: family.case_manager + family.guardian_last_name + family.guardian_first_name,
        health_insurance: family.guardian_health_insurance,
        comments: Faker::Lorem.paragraph,
        active: Faker::Boolean.boolean,
        archived: false,
        item_needed_diaperid: p.organization.item_id_to_display_string_map.key(Partners::Child::CHILD_ITEMS.sample)
      )
    end

    family.home_young_child_count.times do
      Partners::Child.create!(
        family: family,
        first_name: family.guardian_first_name,
        last_name: family.guardian_last_name,
        date_of_birth: Faker::Date.birthday(min_age: 0, max_age: 5),
        gender: Faker::Gender.binary_type,
        child_lives_with: Partners::Child::CAN_LIVE_WITH.sample(2),
        race: Partners::Child::RACES.sample,
        agency_child_id: family.case_manager + family.guardian_last_name + family.guardian_first_name,
        health_insurance: family.guardian_health_insurance,
        comments: Faker::Lorem.paragraph,
        active: Faker::Boolean.boolean,
        archived: false,
        item_needed_diaperid: p.organization.item_id_to_display_string_map.key(Partners::Child::CHILD_ITEMS.sample)
      )
    end
  end

  Faker::Number.within(range: 32..56).times do
    partner_request = ::Request.new(
      partner_id: p.id,
      organization_id: p.organization_id,
      comments: Faker::Lorem.paragraph,
      partner_user_id: p.primary_user.id
    )

    item_requests = [] 
    Array.new(Faker::Number.within(range: 5..15)) do
      item = p.organization.items.sample
      new_item_request = Partners::ItemRequest.new(
        item_id: item.id,
        quantity: Faker::Number.within(range: 10..30),
        children: [],
        name: item.name,
        partner_key: item.partner_key
      )
      partner_request.item_requests << new_item_request
    end

    partner_request.request_items = partner_request.item_requests.map do |ir|
      {
        item_id: ir.item_id,
        quantity: ir.quantity
      }
    end

    partner_request.save!
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
# Product Drives
# ----------------------------------------------------------------------------

[
  {
    name: 'Pamper the Poopsies',
    start_date: Time.current,
    organization: pdx_org
  }
].each { |drive| ProductDrive.create! drive }

# ----------------------------------------------------------------------------
# Product Drive Participants
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
].each { |participant| ProductDriveParticipant.create! participant }

# ----------------------------------------------------------------------------
# Product Drives
# ----------------------------------------------------------------------------

[
  { name: "First Product Drive",
    start_date: 3.years.ago,
    end_date: 3.years.ago,
    organization: sf_org },
  { name: "Best Product Drive",
    start_date: 3.weeks.ago,
    end_date: 2.weeks.ago,
    organization: sf_org },
  { name: "Second Best Product Drive",
    start_date: 2.weeks.ago,
    end_date: 1.week.ago,
    organization: pdx_org }
].each { |product_drive| ProductDrive.find_or_create_by! product_drive }

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
    user: User.with_role(:org_admin, organization).first
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
             when Donation::SOURCES[:product_drive]
               Donation.create! source: source,
                                product_drive: ProductDrive.first,
                                product_drive_participant: random_record_for_org(pdx_org, ProductDriveParticipant),
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
# Vendors
# ----------------------------------------------------------------------------

# Create some Vendors so Purchases can have vendor_ids
Vendor.create(
  contact_name: Faker::FunnyName.two_word_name,
  email: Faker::Internet.email,
  phone: Faker::PhoneNumber.cell_phone,
  comment: Faker::Lorem.paragraph(sentence_count: 2),
  organization_id: pdx_org.id,
  address: "#{Faker::Address.street_address} #{Faker::Address.city}, #{Faker::Address.state_abbr} #{Faker::Address.zip_code}",
  business_name: Faker::Company.name,
  latitude: rand(-90.000000000...90.000000000),
  longitude: rand(-180.000000000...180.000000000),
  created_at: (Time.zone.today - rand(15).days),
  updated_at: (Time.zone.today - rand(15).days),
)
4.times do
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

#re 2813_update_annual_report add some data for last year (enables system testing of reports)
5.times do
  storage_location = random_record_for_org(pdx_org, StorageLocation)
  vendor = random_record_for_org(pdx_org, Vendor)
  Purchase.create(
    purchased_from: suppliers.sample,
    comment: comments.sample,
    organization_id: pdx_org.id,
    storage_location_id: storage_location.id,
    amount_spent_in_cents: rand(200..10_000),
    issued_at: (Time.zone.today - 1.year),
    created_at: (Time.zone.today - 1.year),
    updated_at: (Time.zone.today - 1.year),
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

# ----------------------------------------------------------------------------
# Questions
# ----------------------------------------------------------------------------

titles = [
  "Phasellus volutpat, sem at eleifend?",
  "ante lectus, vestibulum pellentesque arcu sed, eleifend lacinia elit?",
  "nisl, a commodo ligula consequat nec. Aliquam tincidunt diam id placerat rutrum?",
  "molestie tortor. Duis pretium urna eget congue?",
  "eleifend lacinia elit. Cras accumsan varius nisl, a commodo ligula consequat nec. Aliquam?"
]

answers = [
  "urna eget congue porta. Fusce aliquet dolor quis viverra volutpat. nisl, a commodo ligula consequat nec. Aliquam tincidunt diam id placerat rutrum.",
  "ger a molestie tortor. Duis pretium urna eget congue porta. Fusce aliquet dolor quis viv. nas ante lectus, vestibulum pellentesque arcu sed, eleifend lacinia elit. Cras accumsan varius nisl, a commodo ligula consequat nec",
  "que. Phasellus volutpat, sem at eleifend tristique, massa mi cursus dui, eget pharetra.",
  "olutpat, sem at eleifend tristique, massa mi cursus dui, eget pharetra ligula arcu sit amet nunc. aliquet dolor quis viverra volutpat. nisl, a commodo ligula consequat.",
  "Duis pretium urna eget congue porta. Fusce aliquet dolor quis viverra volutpat. Phasellus volutpat, sem at eleifend tristique, massa mi cursus dui, eget pharetra ligula arcu sit amet nunc."
]

5.times do
  Question.create(
    title: "Question for banks. #{titles.sample}",
    for_banks: true,
    for_partners: false,
    answer: "Answer for banks. #{answers.sample}"
  )
  Question.create(
    title: "Question for both. #{titles.sample}",
    for_banks: true,
    for_partners: true,
    answer: "Answer for both. #{answers.sample}"
  )
  Question.create(
    title: "Question for partners. #{titles.sample}",
    for_banks: false,
    for_partners: true,
    answer: "Answer for partners. #{answers.sample}"
  )
end

# ----------------------------------------------------------------------------
# Transfers
# ----------------------------------------------------------------------------
Transfer.create!(
  comment: Faker::Lorem.sentence,
  organization_id: pdx_org.id,
  from_id: pdx_org.id,
  to_id: sf_org.id,
  line_items: [
    LineItem.create!(quantity: 5, item: pdx_org.items.first, itemizable: Distribution.first)
  ]
)