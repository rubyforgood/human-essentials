class InitializeItems < ActiveRecord::Migration[5.2]
  class MigrationCanonicalItem < ActiveRecord::Base
    self.table_name = :canonical_items
  end

  class MigrationItem < ActiveRecord::Base
    self.table_name = :items
  end

  def up
    ci = MigrationCanonicalItem.find_or_initialize_by(name: "Other") do |ci|
      ci.category = "Miscellaneous"
    end
    # Skipping validations because requirements about `partner_key` cause problems if we don't
    ci.save(validate: false)
    MigrationItem.where(canonical_item_id: nil).update_all(canonical_item_id: ci.id)
    MigrationCanonicalItem.reset_column_information
    MigrationItem.reset_column_information
  end
  
  def down
  end
end
