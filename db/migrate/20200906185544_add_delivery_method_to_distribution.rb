class AddDeliveryMethodToDistribution < ActiveRecord::Migration[6.0]
  def change
    # Default to pick_up
    add_column :distributions, :delivery_method, :integer, default: 0, null: false
  end
end
