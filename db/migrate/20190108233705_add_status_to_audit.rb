class AddStatusToAudit < ActiveRecord::Migration[5.2]
  def change
    add_column :audits, :status, :integer, null: false, default: 0
  end
end
