class AllowChildOptOut < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :organizations, :enable_child_based_requests, :boolean, null: false, default: true
      add_column :partner_profiles, :enable_child_based_requests, :boolean, null: false, default: true
    end

  end
end
