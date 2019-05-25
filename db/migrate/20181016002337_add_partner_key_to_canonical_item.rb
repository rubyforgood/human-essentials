# `CanonicalItem` is later renamed to `BaseItem`. It was a bad choice to
# do it this way in a migration, but here we are. The database doesn't
# yet know about the BaseItem name change, but the codebase does.
class CanonicalItem < ApplicationRecord; end

# The partner key is used as the lingua franca when receiving Requests
class AddPartnerKeyToCanonicalItem < ActiveRecord::Migration[5.2]
  def up
    add_column :canonical_items, :partner_key, :string

    canonical_items = File.read(Rails.root.join("db", "base_items.json"))
    items_by_category = JSON.parse(canonical_items)
    # Creates the Canonical Items
    items_by_category.each do |category, entries|
      entries.each do |entry|
        # `CanonicalItem` is later renamed to `BaseItem`. It was a bad choice to
        # do it this way in a migration, but here we are. The database doesn't
        # yet know about the BaseItem name change, but the codebase does.
        c = CanonicalItem.find_or_initialize_by(name: entry["name"])
        c.category ||= category
        c.partner_key = entry["key"]
        c.save
      end
    end
  end

  def down
    remove_column :canonical_items, :partner_key
  end
end
