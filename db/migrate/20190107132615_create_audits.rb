# Initial table for Audits
class CreateAudits < ActiveRecord::Migration[5.2]
  def change
    create_table :audits do |t|
      t.belongs_to :user, index: true
      t.belongs_to :organization, index: true
      t.belongs_to :adjustment, index: true
      t.belongs_to :storage_location, index: true
      t.integer :status, null: false, default: 0
      t.timestamps
    end
  end
end
