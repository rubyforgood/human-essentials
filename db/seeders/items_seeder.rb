# Creates the Base Items

class ItemsSeeder
  BASE_ITEMS = JSON.parse(File.read(Rails.root.join("db", "base_items.json")))

  def self.seed
    BASE_ITEMS.each do |category, entries|
      entries.each { |entry| create_base_item(entry, category) }
    end
  end

  def self.create_base_item(entry, category)
    BaseItem.find_or_create_by!(
      name: entry["name"],
      category: category,
      partner_key: entry["key"]
    )
  end
end
