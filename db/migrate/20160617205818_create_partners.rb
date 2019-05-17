# Creates the initial Partners table
class CreatePartners < ActiveRecord::Migration[5.0]
  def change
    create_table :partners do |t|
      t.string :name
      t.string :email

      t.timestamps
    end

    add_reference :tickets, :partner, index: true, foreign_key: true
  end
end
