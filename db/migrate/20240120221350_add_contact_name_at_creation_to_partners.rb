class AddContactNameAtCreationToPartners < ActiveRecord::Migration[7.0]
  def up
    safety_assured {
      add_column :partners, :contact_name_at_creation, :string
    }
  end

  def down
    remove_column :partners, :contact_name_at_creation
  end
end
