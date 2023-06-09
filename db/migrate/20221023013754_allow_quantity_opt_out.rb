class AllowQuantityOptOut < ActiveRecord::Migration[7.0]
  def change
    # Adding new columns with default values is safe in Postgres 11+
    safety_assured do
      add_column :organizations, :enable_quantity_based_requests, :boolean, null: false, default: true
      add_column :partner_profiles, :enable_quantity_based_requests, :boolean, null: false, default: true
    end
  end
end
