class AddReportingCategoryToBaseItem < ActiveRecord::Migration[7.2]
  def change
    add_column :base_items, :reporting_category, :string
  end
end
