class InitializeItems < ActiveRecord::Migration[5.2]
  def up
    ci = CanonicalItem.find_or_initialize_by(name: "Other") do |ci|
      ci.category = "Miscellaneous"
    end
    # Skipping validations because requirements about `partner_key` cause problems if we don't
    ci.save(validate: false)
    Item.where(canonical_item_id: nil).update_all(canonical_item_id: ci.id)
    CanonicalItem.reset_column_information
    Item.reset_column_information
  end
  
  def down
  end
end
