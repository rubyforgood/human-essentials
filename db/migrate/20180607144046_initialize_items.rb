# `CanonicalItem` is later renamed to `BaseItem`. It was a bad choice to
# do it this way in a migration, but here we are. The database doesn't
# yet know about the BaseItem name change, but the codebase does.
class CanonicalItem < ApplicationRecord; end

# This ensures that every existing item is associated with a canonical/base item
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
