class AddShowYtdValuesOnDistributionPrintoutToOrganization < ActiveRecord::Migration[7.0]
  def change
    safety_assured { add_column :organizations, :show_ytd_values_on_distribution_printout, :boolean, default: true, null: false }
  end
end
