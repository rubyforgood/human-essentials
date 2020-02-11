# One resource to rule them all....
class CreateOrganizations < ActiveRecord::Migration[5.0]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :short_name
      t.text :address
      t.string :email
      t.string :url

      t.timestamps
    end

    add_index :organizations, :short_name
  end
end
