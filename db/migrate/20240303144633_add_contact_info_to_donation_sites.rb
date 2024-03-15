class AddContactInfoToDonationSites < ActiveRecord::Migration[7.0]
  def change
    change_table :donation_sites do |t|
      t.string :contact_name
      t.string :email
      t.string :phone
    end
  end
end
