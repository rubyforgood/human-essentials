class EncryptDatesOfBirth < ActiveRecord::Migration[8.0]
  def up
    # date -> text: encrypted values are string blobs and won't fit a date column.
    safety_assured do
      change_column :children, :date_of_birth, :text
      change_column :authorized_family_members, :date_of_birth, :text
    end
  end

  def down
    safety_assured do
      change_column :children, :date_of_birth, :date, using: "date_of_birth::date"
      change_column :authorized_family_members, :date_of_birth, :date, using: "date_of_birth::date"
    end
  end
end
