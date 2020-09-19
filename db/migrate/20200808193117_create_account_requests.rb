class CreateAccountRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :account_requests do |t|
      t.string :name, null: false
      t.string :email, null: false, unique: true
      t.string :organization_name, null: false
      t.string :organization_website
      t.datetime :confirmed_at
      t.text :request_details, null: false

      t.timestamps
    end

    add_column :organizations, :account_request_id, :integer
    add_foreign_key :organizations, :account_requests
  end
end
