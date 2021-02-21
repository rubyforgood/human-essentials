class AddArchivedToChild < ActiveRecord::Migration[5.2]
  def change
    add_column :children, :archived, :boolean
  end
end
