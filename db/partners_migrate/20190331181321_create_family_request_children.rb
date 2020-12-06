class CreateFamilyRequestChildren < ActiveRecord::Migration[5.2]
  def change
    create_table :family_request_children do |t|
      t.references :family_request, foreign_key: true
      t.references :child, foreign_key: true

      t.timestamps
    end
  end
end
