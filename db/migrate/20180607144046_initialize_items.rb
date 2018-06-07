class InitializeItems < ActiveRecord::Migration[5.2]
  def up
    puts "Initializing all Items that do not currently have a CanonicalItem"
    print "Setting them to: "
    ci = CanonicalItem.find_or_create_by(name: "Other") do |ci|
      ci.category = "Miscellaneous"
    end
    puts "id: #{ci.id}, name: #{ci.name}"
    Item.where(canonical_item_id: nil).update_all(canonical_item_id: ci.id)
    puts "Records initialized to #{ci.name}: #{Item.where(canonical_item_id: ci.id).count}"
  end
  def down
  end
end
