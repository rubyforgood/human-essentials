class FixBaseItemReportingCategoryData < ActiveRecord::Migration[7.2]
  def change
    BaseItem.reset_column_information

    BaseItem.find_each do |base_item|
      base_item.save!
    end
  end
end
