module Seeds
  def self.random_record_for_org(org, klass)
    klass.where(organization: org).all.sample
  end

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

  def self.seed_random_item_with_name(organization, name)
    # Once we break the link between BaseItem and Item, we can remove the 'kit' BaseItem, and change this to BaseItem.all CLF 20251202
    base_items = BaseItem.where.not(reporting_category: nil).map(&:to_h)
    base_item = Array.wrap(base_items).sample
    base_item[:name] = name
    organization.seed_items(base_item)
  end

  def self.seed_quantity(item_name, organization, storage_location, quantity)
    return if quantity.zero?

    item = Item.find_by(name: item_name, organization: organization)

    adjustment = organization.adjustments.create!(
      comment: "Starting inventory",
      storage_location: storage_location,
      user: User.with_role(:org_admin, organization).first
    )
    adjustment.line_items = [LineItem.new(quantity: quantity, item: item, itemizable: adjustment)]
    AdjustmentCreateService.new(adjustment).call
  end

  def self.skip_dupes_and_seed(collection)
    errors = []
    collection.each do |entry|
      yield entry
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      errors << e.to_s
      Rails.logger.info "[SEEDS] Error while adding #{entry.inspect} - #{e}"
    end
    errors
  end
end
