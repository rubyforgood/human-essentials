class CreatePartners < ActiveRecord::Migration
  def change
    create_table :partners do |t|
      t.string :name
      t.string :email

      t.timestamps
    end
    
    add_reference :tickets, :partner, index: true, foreign_key: true
  end
end
