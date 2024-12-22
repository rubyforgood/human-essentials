class CreateTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags do |t|
      t.string :name, limit: 256, null: false, index: {unique: true}

      t.timestamps
    end
  end
end
