class CleanUpBaseItems < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :base_items, :size, :string
      remove_column :base_items, :barcode_count, :integer
    end
  end
end
