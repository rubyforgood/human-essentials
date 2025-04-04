class FixLinersReportingCategory < ActiveRecord::Migration[8.0]
  def up
    BaseItem
      .where(name: "Liners (Menstrual)")
      .update_all(reporting_category: :period_liners)

    Item
      .joins(:base_item)
      .where(base_item: { name: "Liners (Menstrual)" })
      .update_all(reporting_category: :period_liners)
  end

  def down
    BaseItem
      .where(name: "Liners (Menstrual)")
      .update_all(reporting_category: :menstrual)

    Item
      .joins(:base_item)
      .where(base_item: { name: "Liners (Menstrual)"})
      .update_all(reporting_category: :menstrual)
  end
end
