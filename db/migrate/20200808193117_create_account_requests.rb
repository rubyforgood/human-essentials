class CreateAccountRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :account_requests do |t|
      t.string :email, null: false, unique: true
      t.string :organization_name, null: false
      t.string :organization_website
      t.text :request_details, null: false

      t.timestamps
    end
  end
end
