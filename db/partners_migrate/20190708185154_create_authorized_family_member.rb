class CreateAuthorizedFamilyMember < ActiveRecord::Migration[5.2]
  def change
    create_table :authorized_family_members do |t|
      t.string :first_name
      t.string :last_name
      t.date :date_of_birth
      t.string :gender
      t.text :comments
      t.references :family, foreign_key: true

      t.timestamps
    end
  end
end
