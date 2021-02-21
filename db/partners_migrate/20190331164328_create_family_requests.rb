class CreateFamilyRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :family_requests do |t|
      t.references :partner, foreign_key: true

      t.timestamps
    end
  end
end
