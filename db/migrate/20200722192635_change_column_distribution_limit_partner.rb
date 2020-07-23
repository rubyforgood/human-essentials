class ChangeColumnDistributionLimitPartner < ActiveRecord::Migration[6.0]
  def change
    change_column_default :partners, :distribution_limit, 0
  end
end
