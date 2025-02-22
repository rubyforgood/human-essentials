class BackfillReportingCategoryForBaseItems < ActiveRecord::Migration[7.2]
  def up
    # A before_save validation has been added. so saving each record fills
    # in the reporting_category field.
    BaseItem.find_each do |base_item|
      base_item.save!
    end
  end

  def down
    BaseItem.update_all(reporting_category: nil)
  end
end
