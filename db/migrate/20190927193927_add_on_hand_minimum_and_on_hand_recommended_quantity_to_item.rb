class AddOnHandMinimumAndOnHandRecommendedQuantityToItem < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :on_hand_minimum_quantity, :integer, null: false, default: 0
    add_column :items, :on_hand_recommended_quantity, :integer, default: nil
  end
end
