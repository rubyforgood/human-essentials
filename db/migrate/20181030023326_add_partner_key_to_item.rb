class AddPartnerKeyToItem < ActiveRecord::Migration[5.2]
  class MigrationCanonicalItem < ActiveRecord::Base
    self.table_name = :canonical_items
  end

  class MigrationItem < ActiveRecord::Base
    self.table_name = :items
  end

  def up
    add_column :items, :partner_key, :string
    add_index :items, :partner_key

    # Migrate existing references to partner keys
    canonical_items = MigrationCanonicalItem.pluck(:id, :partner_key).to_h
    MigrationItem.update_all(partner_key: canonical_items[i.canonical_item_id])

    remove_column :items, :canonical_item_id
  end

  def down
    add_column :items, :canonical_item_id, :integer

    # Migrate existing references back to numerical id
    canonical_items = MigrationCanonicalItem.pluck(:partner_key, :id).to_h
    MigrationItem.update_all(canonical_item_id: canonical_items[i.partner_key])

    remove_index :items, :partner_key
    remove_column :items, :partner_key
  end
end
