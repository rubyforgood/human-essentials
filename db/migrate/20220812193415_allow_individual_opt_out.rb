class AllowIndividualOptOut < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :organizations, :enable_individual_requests, :boolean, null: false, default: true
      add_column :partner_profiles, :enable_individual_requests, :boolean, null: false, default: true
    end
  end
end
