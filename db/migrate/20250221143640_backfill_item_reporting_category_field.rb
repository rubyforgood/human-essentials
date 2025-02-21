class BackfillItemReportingCategoryField < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    # To be safe
    Item.reset_column_information
    BaseItem.reset_column_information

    # Get the pairing of partner_keys (foreign key to pair base items with items)
    # to reporting category from BaseItem table.
    mappings = BaseItem
      .group(:reporting_category)
      .where.not(reporting_category: nil)
      .pluck("reporting_category, ARRAY_AGG(base_items.partner_key)")
      .to_h

    # For each batch of 1000 records, run a query for each reporting category,
    # updating items with that partner key to have matching reporting category.
    # In production, we have ~12k items and there are 7 reporting categories
    # so this should be around ~100 queries.
    Item.unscoped.in_batches do |relation|
      mappings.each do |reporting_category, partner_keys|
        relation.where(partner_key: partner_keys)
          .update_all(reporting_category: reporting_category)

        sleep(0.1) # Throttle
      end
    end
  end

  def down
    Item.unscoped.in_batches do |relation|
      relation.update_all(reporting_category: nil)
      # Throttle
      sleep(0.1)
    end
  end
end
