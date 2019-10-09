# Creates the Base Items

class ItemsSeeder
  BASE_ITEMS = File.read(Rails.root.join("db", "base_items.json"))

  def self.seed
    items_by_category = JSON.parse(BASE_ITEMS)

    items_by_category.each do |category, entries|
      entries.each { |entry| create_base_item(entry, category) }
    end

    items_by_category
  end

  def self.create_base_item(entry, category)
    BaseItem.find_or_create_by!(
      name: entry["name"],
      category: category,
      partner_key: entry["key"]
    )
  end
end
