class CreateFamilies < ActiveRecord::Migration[5.2]
  def change
    create_table :families do |t|
      t.string :guardian_first_name
      t.string :guardian_last_name
      t.string :guardian_zip_code
      t.string :guardian_country
      t.string :guardian_phone
      t.string :agency_guardian_id
      t.integer :home_adult_count
      t.integer :home_child_count
      t.integer :home_young_child_count
      t.jsonb :sources_of_income
      t.boolean :guardian_employed
      t.jsonb :guardian_employment_type
      t.decimal :guardian_monthly_pay
      t.jsonb :guardian_health_insurance
      t.text :comments

      t.timestamps
    end
  end
end
