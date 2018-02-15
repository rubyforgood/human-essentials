class AddDistributionDateToDistributions < ActiveRecord::Migration[5.1]
  def change
    add_column :distributions, :distribution_date, :date
  end
end
