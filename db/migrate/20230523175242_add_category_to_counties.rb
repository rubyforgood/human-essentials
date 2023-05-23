class AddCategoryToCounties < ActiveRecord::Migration[7.0]
  def change
    add_column :counties, :category, :string
  end
end
