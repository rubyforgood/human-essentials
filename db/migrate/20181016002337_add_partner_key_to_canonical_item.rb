class AddPartnerKeyToCanonicalItem < ActiveRecord::Migration[5.2]
  class MigrationCanonicalItem < ActiveRecord::Base
    self.table_name = :canonical_items
  end

  def up
    add_column :canonical_items, :partner_key, :string
    canonical_items = File.read(Rails.root.join("db", "canonical_items.json"))
    items_by_category = JSON.parse(canonical_items)
    # Creates the Canonical Items
    items_by_category.each do |category, entries|
      entries.each do |entry|
        c = MigrationCanonicalItem.find_or_initialize_by(name: entry["name"])
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
