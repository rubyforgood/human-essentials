class AddMilitaryFamilytoFamilies < ActiveRecord::Migration[5.2]
  def change
    add_column :families, :military, :boolean, default: false
  end
end
