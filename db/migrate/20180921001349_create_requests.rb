# Creates initial table for Requests
class CreateRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :requests do |t|
      t.references :partner, foreign_key: true
      t.references :organization, foreign_key: true
      t.string :status, default: 'Active'
      t.jsonb :request_items, default: {}
      t.text :comments

      t.timestamps
    end
  end
end
