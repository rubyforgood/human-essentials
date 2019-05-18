# Fix to ensure that the object is available in the migration
class Partner < ApplicationRecord
end

# We're moving Partners to an Enum, so seeding them initially with integers
class MovePartnerStatusToAnIntergerType < ActiveRecord::Migration[5.2]
  def up
    # 1. add_column that is an integer type where we can move our string to ints
    add_column :partners, :temp_status, :integer, default: 0

    # "Pending" => 0; etc.
    # 2. Map status data from the "status" to our new "temp_status"
    puts "updating Pending partners. will update #{Partner.where(status: "Pending").count} partners"
    Partner.where(status: "Pending").update_all(temp_status: 0)

    # 2.1 map "Awaiting Review" to 1
    puts "updating Awaiting Review partners. will update #{Partner.where(status: "Awaiting Review").count} partners"
    Partner.where(status: "Awaiting Review").update_all(temp_status: 1)

    # 2.2 map "Approved" to 2
    puts "updating Approved partners. will update #{Partner.where(status: "Approved").count} partners"
    Partner.where(status: "Approved").update_all(temp_status: 2)

    # 2.3 map "Error" to 3
    puts "updating Approved partners. will update #{Partner.where(status: "Error").count} partners"
    Partner.where(status: "Error").update_all(temp_status: 3)

    # 2.4 print those partners which could not be migrated
    # We assume that all partners will conform to the previous string statuses
    # but maybe not. At least we can capture them here if not.
    Partner.where.not(status: ["Pending", "Awaiting Review", "Approved", "Error"]).each do |partner|
      puts "Could not update Partner #{partner.id} with status #{partner.status}"
      puts partner.inspect
    end

    # 3. Delete "status"
    puts "removing status column"
    remove_column :partners, :status

    # 4. Rename "temp_status" -> "status"
    puts "renaming temp_status to status"
    rename_column :partners, :temp_status, :status
  end

  def down
    # 1. add_column that is an string type where we can move our ints to strings
    add_column :partners, :temp_status, :string

    # 2. map 0 value to "pending" value
    puts "updating Pending partners. will update #{Partner.where(status: 0).count} partners"
    Partner.where(status: 0).update_all(temp_status: "Pending")

    # 2.1 map 1 value to "Awaiting Review" value
    puts "updating Awaiting Review partners. will update #{Partner.where(status: 1).count} partners"
    Partner.where(status: 1).update_all(temp_status: "Awaiting Review")

    # 2.2 map 2 value to "Approved" value
    puts "updating Approved partners. will update #{Partner.where(status: 2).count} partners"
    Partner.where(status: 2).update_all(temp_status: "Approved")

    # 2.3 map 3 value to "Error" value
    puts "updating Approved partners. will update #{Partner.where(status: 3).count} partners"
    Partner.where(status: 3).update_all(temp_status: "Error")

    # 3. Delete "status" column
    puts "removing status column"
    remove_column :partners, :status

    # 4. Rename "temp_status" -> "status"
    puts "renaming temp_status to status"
    rename_column :partners, :temp_status, :status
  end
end
