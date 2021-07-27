class CreateChildren < ActiveRecord::Migration[5.2]
  def change
    create_table :children do |t|
      t.string :first_name
      t.string :last_name
      t.date :date_of_birth
      t.string :gender
      t.jsonb :child_lives_with
      t.jsonb :race
      t.string :agency_child_id
      t.jsonb :health_insurance
      t.string :item_needed
      t.text :comments

      t.timestamps
    end
  end
end
