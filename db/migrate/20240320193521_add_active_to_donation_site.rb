class AddActiveToDonationSite < ActiveRecord::Migration[7.0]
  def up
    add_column :donation_sites, :active, :boolean
    change_column_default :donation_sites, :active, true
  end
  def down
    remove_column :donation_sites, :active
  end
end
