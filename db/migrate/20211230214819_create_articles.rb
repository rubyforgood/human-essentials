class CreateArticles < ActiveRecord::Migration[6.1]
  def change
    create_table :articles do |t|
      t.string :question
      t.boolean :for_partners
      t.boolean :for_banks

      t.timestamps
    end
  end
end
