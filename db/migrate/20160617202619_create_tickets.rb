# Creates the initial "Tickets" table, these are later renamed "Distributions"
class CreateTickets < ActiveRecord::Migration[5.0]
  def change
    create_table :tickets do |t|
      t.text :comment
      t.timestamps
    end

    add_reference :tickets, :inventory, index: true, foreign_key: true
  end
end
