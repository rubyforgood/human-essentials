class CreateTaggings < ActiveRecord::Migration[7.2]
  def change
    create_table :taggings do |t|
      t.belongs_to :organization, null: false, foreign_key: true
      t.belongs_to :tag, null: false, foreign_key: true
      t.references :taggable, polymorphic: true, null: false, index: false
      t.index [:taggable_type, :taggable_id, :tag_id], unique: true

      t.timestamps
    end
  end
end
