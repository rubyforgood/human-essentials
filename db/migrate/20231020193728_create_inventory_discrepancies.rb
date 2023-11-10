class CreateInventoryDiscrepancies < ActiveRecord::Migration[7.0]
  def change
    create_table :inventory_discrepancies do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true, name: 'event_id'
      t.json :diff
      t.timestamps

      t.index [:organization_id, :created_at]
    end
  end
end
