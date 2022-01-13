class CreateQuestions < ActiveRecord::Migration[6.1]
  def change
    create_table :questions do |t|
      t.string :title
      t.boolean :for_partners
      t.boolean :for_banks

      t.timestamps
    end
  end
end
