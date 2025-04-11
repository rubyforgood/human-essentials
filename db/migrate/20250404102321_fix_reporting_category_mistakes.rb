class FixReportingCategoryMistakes < ActiveRecord::Migration[8.0]
  def up
    # Fix for categorization mistake
    BaseItem
      .where(name: "Liners (Menstrual)")
      .update_all(reporting_category: :period_liners)

    Item
      .joins(:base_item)
      .where(base_item: { name: "Liners (Menstrual)" })
      .update_all(reporting_category: :period_liners)

    # Fix for typo mistake in BaseItem::NAME_TO_REPORTING_CATEGORY
    BaseItem
      .where(name: "Adult Incontinence Pads")
      .update_all(reporting_category: :adult_incontinence)

    Item
      .joins(:base_item)
      .where(base_item: { name: "Adult Incontinence Pads" })
      .update_all(reporting_category: :adult_incontinence)
  end

  def down
  end
end
