module Seeds
  def self.seed_base_items
    # Initial starting qty for our test organizations
    base_items = Rails.root.join("db", "base_items.json").read
    items_by_category = JSON.parse(base_items)

    items_by_category.each do |category, entries|
      entries.each do |entry|
        BaseItem.find_or_create_by!(
          name: entry["name"],
          category: category,
          partner_key: entry["key"],
          updated_at: Time.zone.now,
          created_at: Time.zone.now
        )
      end
    end
    # Create global 'Kit' base item
    KitCreateService.find_or_create_kit_base_item!
  end
end
