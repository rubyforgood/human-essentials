class AddEnableReplenishmentPlannerToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :enable_replenishment_planner, :boolean, null: false, default: false
  end
end
