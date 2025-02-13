class CreateTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags do |t|
      t.string :name, limit: 256, null: false
      t.string :type, null: false
      t.belongs_to :organization, null: false, foreign_key: true

      t.index [:type, :organization_id, :name], unique: true

      t.timestamps
    end
  end
end
