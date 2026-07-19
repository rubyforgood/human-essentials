class AddIncludePackagesInDistributionExportToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :include_packages_in_distribution_export, :boolean, default: false, null: false
  end
end
