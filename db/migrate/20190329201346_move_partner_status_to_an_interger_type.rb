class MovePartnerStatusToAnIntergerType < ActiveRecord::Migration[5.2]
  def up
    # 1. add_column that is an integer type where we can move our string to ints
    add_column :partners, :temp_status, :integer, default: 0
    # "Pending" => 0; etc.
    # 2. Map status data from the "status" to our new "temp_status"
    puts "updating Pending partners. will update #{Partner.where(status: "Pending").count} partners"
    Partner.where(status: "Pending").update_all(temp_status: 0)
    puts "updating Awaiting Review partners. will update #{Partner.where(status: "Awaiting Review").count} partners"
    Partner.where(status: "Awaiting Review").update_all(temp_status: 1)
    puts "updating Approved partners. will update #{Partner.where(status: "Approved").count} partners"
    Partner.where(status: "Approved").update_all(temp_status: 2)
    # 3. Delete "status"
    puts "removing status column"
    remove_column :partners, :status
    # 4. Rename "temp_status" -> "status"
    puts "renaming temp_status to status"
    rename_column :partners, :temp_status, :status
  end

  def down
    # this is probably reversible
    # we should give that a try
  end
end
