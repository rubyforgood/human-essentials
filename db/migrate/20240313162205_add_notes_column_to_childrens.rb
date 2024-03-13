class AddNotesColumnToChildrens < ActiveRecord::Migration[7.0]
  def change
    add_column :children, :notes, :string
  end
end
