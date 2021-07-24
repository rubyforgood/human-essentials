class AddLineItemsTotalToAudits < ActiveRecord::Migration[6.1]
  def self.up
    add_column :audits, :line_items_total, :integer, null: false, default: 0
  end

  def self.down
    remove_column :audits, :line_items_total
  end
end
