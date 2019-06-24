class AddAasmStateToDistribution < ActiveRecord::Migration[5.2]
  def change
    add_column :distributions, :aasm_state, :string
  end
end
