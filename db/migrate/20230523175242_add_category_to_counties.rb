class AddCategoryToCounties < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      create_enum :category, ["US_County", "Other"]
      change_table :counties do |t|
        t.enum :category, enum_type: "category", default: "US_County", null: false
      end
    end
  end
end
