class AddStateToDistribution < ActiveRecord::Migration[5.2]
  def change
    add_column :distributions, :state, :integer, null: false, default: 0
  end
end
