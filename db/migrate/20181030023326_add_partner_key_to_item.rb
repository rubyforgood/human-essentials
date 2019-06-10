# `CanonicalItem` is later renamed to `BaseItem`. It was a bad choice to
# do it this way in a migration, but here we are. The database doesn't
# yet know about the BaseItem name change, but the codebase does.  
class CanonicalItem < ApplicationRecord; end

# Stubbed class for forward compatibility
class Item < ApplicationRecord; end

# Uses `:partner_key` as the foreign key to connect Items and CanonicalItems
class AddPartnerKeyToItem < ActiveRecord::Migration[5.2]
  def up
    add_column :items, :partner_key, :string
    add_index :items, :partner_key

    # Migrate existing references to partner keys
    canonical_items = CanonicalItem.pluck(:id, :partner_key).to_h
    Item.all.each do |i|
      i.update_attribute(:partner_key, canonical_items[i.canonical_item_id])
    end

    remove_column :items, :canonical_item_id
  end

  def down
    add_column :items, :canonical_item_id, :integer

    # Migrate existing references back to numerical id
    canonical_items = CanonicalItem.pluck(:partner_key, :id).to_h
    Item.all.each do |i|
      i.update_attribute(:canonical_item_id, canonical_items[i.partner_key])
    end

    remove_index :items, :partner_key
    remove_column :items, :partner_key
  end
end
