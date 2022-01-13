class DropArticles < ActiveRecord::Migration[6.1]
  def change
    drop_table :articles
  end
end
