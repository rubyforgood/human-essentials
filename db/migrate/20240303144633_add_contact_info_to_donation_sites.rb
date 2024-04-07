class AddContactInfoToDonationSites < ActiveRecord::Migration[7.0]
  def change
    add_column :donation_sites, :contact_name, :string
    add_column :donation_sites, :email, :string
    add_column :donation_sites, :phone, :string
  end
end
