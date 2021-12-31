class CreateArticles < ActiveRecord::Migration[6.1]
  def change
    create_table :articles do |t|
      t.string :question
      t.boolean :for_partners
      t.boolean :for_organizations

      t.timestamps
    end
  end
end
