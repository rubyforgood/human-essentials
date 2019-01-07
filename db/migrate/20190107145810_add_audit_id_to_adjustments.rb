class AddAuditIdToAdjustments < ActiveRecord::Migration[5.2]
  def change
    add_column :adjustments, :audit_id, :integer
  end
end
