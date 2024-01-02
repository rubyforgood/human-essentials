class AddYtdValuesOnDistributionPrintoutToOrganization < ActiveRecord::Migration[7.0]
  def change
    safety_assured { add_column :organizations, :ytd_on_distribution_printout, :boolean, default: true, null: false }
  end
end
