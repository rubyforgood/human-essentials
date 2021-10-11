class AddRacesToPartnersTable < ActiveRecord::Migration[6.1]
  def change
    add_column :partners, :population_middle_eastern, :integer
    add_column :partners, :population_northern_african, :integer
  end
end
