class AddArchiveToFamilies < ActiveRecord::Migration[7.0]
  def up
    add_column :families, :archived, :boolean, nil: false, default: false
  end

  def down
    remove_column :families, :archived
  end
end
