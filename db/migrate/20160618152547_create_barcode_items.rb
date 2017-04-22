class CreateBarcodeItems < ActiveRecord::Migration
  def change
    create_table :barcode_items do |t|
      t.string :value
      t.integer :item_id
      t.integer :quantity

      t.timestamps null: false
    end
  end
end
