# This file should contain all the record creation needed to seed the database with demo values.
# The data can then be loaded with `rails db:seed` (or along with the creation of the db with `rails db:setup`).
unless Rails.env.development?
  puts "Database seeding has been configured to work only in development mode."
  return
end

Dir[
  File.join(Rails.root, 'db', 'seeders', '**/', '*.rb')
].each { |seeder| require seeder }

def random_record_for_org(org, klass)
  Helpers::SqlHelper.random_record_for_org(klass, org)
end

# Initial starting qty for our test organizations
items_by_category = ItemsSeeder.seed

OrganizationsSeeder.seed
pdx_org = Organization.find_by(short_name: 'diaper_bank')
sf_org  = Organization.find_by(short_name: 'sf_bank')

# Assign a value to some organization items to verify totals are working
Organization.all.each do |org|
  org.items.where(value_in_cents: 0).limit(10).update_all(value_in_cents: 100)
end

# super admin
UserSeeder.seed({ email: 'superadmin@example.com', organization_admin: false, super_admin: true})

# org admins
UserSeeder.seed({ email: 'org_admin1@example.com', organization_admin: true }, pdx_org)
UserSeeder.seed({ email: 'org_admin2@example.com', organization_admin: true }, sf_org)

# regular users
UserSeeder.seed({ email: 'user_1@example.com', organization_admin: false }, pdx_org)
UserSeeder.seed({ email: 'user_2@example.com', organization_admin: false }, sf_org)

# test users
UserSeeder.seed({ email: 'test@example.com',
                  organization_admin: false,
                  super_admin: true }, pdx_org)
UserSeeder.seed({ email: 'test2@example.com', organization_admin: true }, sf_org)

DonationSitesSeeder.seed(pdx_org)

PartnersSeeder.seed(pdx_org)

StorageLocationsSeeder.seed(pdx_org, "Bulk Storage Location")
StorageLocationsSeeder.seed(pdx_org, "Pawnee Main Bank (Office)")

DiaperDriverParticipantsSeeder.seed(pdx_org)

ManufacturersSeeder.seed(pdx_org)

QuantitySeeder.seed(pdx_org, items_by_category)

BarcodeItemsSeeder.seed(pdx_org)

# Make some donations of all sorts
DonationsSeeder.seed(pdx_org)

# Make some distributions, but don't use up all the inventory
DistributionsSeeder.seed(pdx_org)

RequestsSeeder.seed(pdx_org)

# Create some Vendors so Purchases can have vendor_ids
VendorsSeeder.seed

# Create purchases
PurchasesSeeder.seed(pdx_org)

Flipper::Adapters::ActiveRecord::Feature.find_or_create_by(key: "new_logo")
