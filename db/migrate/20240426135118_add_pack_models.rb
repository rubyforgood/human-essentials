class AddPackModels < ActiveRecord::Migration[7.0]
  def change
    create_table :request_units do |t|
      t.string :name, null: false
      t.references :organization, foreign_key: true
      t.timestamps
    end

    create_table :item_request_units do |t|
      t.string :name, null: false
      t.references :item, foreign_key: true
      t.timestamps
    end

    safety_assured do
      add_column :organizations, :uses_request_units, :boolean, null: false, default: false
      add_column :items, :reporting_unit, :string
    end

  end
end
