class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.text :comment
      t.timestamps
    end

    add_reference :tickets, :inventory, index: true, foreign_key: true
  end
end
