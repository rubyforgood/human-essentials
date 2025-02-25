class FixBaseItemReportingCategoryData < ActiveRecord::Migration[7.2]
  def up
    BaseItem.find_each do |base_item|
      base_item.save!
    end
  end

  def down
    BaseItem.find_each do |base_item|
      base_item.update!(reporting_category: base_item.reporting_category.titleize)
    end
  end
end
