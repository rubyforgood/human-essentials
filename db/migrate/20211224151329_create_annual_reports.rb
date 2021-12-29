class CreateAnnualReports < ActiveRecord::Migration[6.1]
  def change
    create_table :annual_reports do |t|
      t.references :organization, index: true, foreign_key: true
      t.integer :year
      t.json :all_reports

      t.timestamps
    end
  end
end
