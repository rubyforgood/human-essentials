class InitializeItems < ActiveRecord::Migration[5.2]
  def up
    ci = CanonicalItem.find_or_create_by(name: "Other") do |ci|
      ci.category = "Miscellaneous"
    end
    Item.where(canonical_item_id: nil).update_all(canonical_item_id: ci.id)
  end
  
  def down
  end
end
