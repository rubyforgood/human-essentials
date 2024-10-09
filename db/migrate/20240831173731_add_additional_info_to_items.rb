class AddAdditionalInfoToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :additional_info, :text
  end
end
