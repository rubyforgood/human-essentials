class AddNotesColumnToFamilies < ActiveRecord::Migration[7.0]
  def change
    add_column :families, :notes, :string
  end
end
