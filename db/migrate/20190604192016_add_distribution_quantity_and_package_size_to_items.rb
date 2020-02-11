class AddDistributionQuantityAndPackageSizeToItems < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :package_size, :integer
    add_column :items, :distribution_quantity, :integer
  end
end
