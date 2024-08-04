class BackfillPartnerChildRequestedItems < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      execute <<-SQL
      INSERT INTO children_items (child_id, item_id)
      SELECT children.id, items.id
      FROM children
      LEFT JOIN items ON children.item_needed_diaperid = items.id
      WHERE items.id IS NOT NULL AND children.item_needed_diaperid IS NOT NULL
      SQL
    end
  end
end
