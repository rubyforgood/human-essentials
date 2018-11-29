class AddWeightsToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :weight_in_grams, :integer
    add_column :canonical_items, :weight_in_grams, :integer
  end
end
