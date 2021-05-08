class ChangeStateDefaultOnDistributions < ActiveRecord::Migration[6.1]
  def change
    change_column_default :distributions, :state, from: 0, to: 5
  end
end
