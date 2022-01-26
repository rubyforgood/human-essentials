class CreateQuestions < ActiveRecord::Migration[6.1]
  def change
    create_table :questions do |t|
      t.string :title, null: false
      t.boolean :for_partners, null: false, default: true
      t.boolean :for_banks, null: false, default: true

      t.timestamps
    end
  end
end
