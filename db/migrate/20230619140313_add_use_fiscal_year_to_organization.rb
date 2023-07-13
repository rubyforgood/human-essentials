class AddShowYtdValuesOnDistributionPrintoutToOrganization < ActiveRecord::Migration[7.0]
  def change
    safety_assured { add_column :organizations, :use_fiscal_year, :boolean, default: true, null: false }
  end
end
