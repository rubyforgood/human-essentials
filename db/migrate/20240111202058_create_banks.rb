class CreateBanks < ActiveRecord::Migration[7.0]
  def change
    create_table :banks do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :address
      t.boolean :opt_in_email_notification
      t.timestamps
    end
  end
end
