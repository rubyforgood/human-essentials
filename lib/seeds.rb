module Seeds
  def self.seed_base_items
    # Initial starting qty for our test organizations
    base_items = Rails.root.join("db", "base_items.json").read
    items_by_category = JSON.parse(base_items)

    items_by_category.each do |category, entries|
      entries.each do |entry|
        # No timestamps here. `find_or_create_by!` builds its lookup from every attribute it is
        # given, so passing `created_at: Time.zone.now` put "created at this exact instant" into
        # the WHERE clause -- which no existing row can match. The find missed every time and fell
        # through to a create that tripped BaseItem's unscoped uniqueness on `name` and
        # `partner_key`, so a second `db:seed` raised "Name has already been taken". Rails sets
        # both timestamps on create anyway.
        BaseItem.find_or_create_by!(
          name: entry["name"],
          category: category,
          partner_key: entry["key"]
        )
      end
    end
    # Create global 'Kit' base item
    KitCreateService.find_or_create_kit_base_item!
  end
end
