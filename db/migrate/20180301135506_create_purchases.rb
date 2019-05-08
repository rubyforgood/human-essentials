# Stakeholder wanted the ability to track inventory purchased directly
class CreatePurchases < ActiveRecord::Migration[5.1]
  def change
    create_table :purchases do |t|
      t.string :purchased_from
      t.text :comment
      t.belongs_to :organization, index: true, type: :integer
      t.belongs_to :storage_location, index:true, type: :integer
      t.integer :amount_spent
      t.datetime :issued_at

      t.timestamps
    end
  end
end
