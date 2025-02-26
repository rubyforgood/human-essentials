class AddReportingCategoryToItems < ActiveRecord::Migration[7.2]
  def change
    add_column :items, :reporting_category, :string
  end
end
