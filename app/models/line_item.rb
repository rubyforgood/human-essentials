# == Schema Information
#
# Table name: line_items
#
#  id              :bigint(8)        not null, primary key
#  quantity        :integer
#  item_id         :integer
#  itemizable_id   :integer
#  itemizable_type :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class LineItem < ApplicationRecord
  belongs_to :itemizable, polymorphic: true, inverse_of: :line_items, optional: false
  belongs_to :item

  validates :item_id, presence: true
  validates :quantity, numericality: { other_than: 0, only_integer: true }
  scope :active, -> { joins(:item).where(items: { active: true }) }

  def value_per_line_item
    item.value_in_cents * quantity
  end

  def self.items_out(storage_location_id, organization_id)
    joins("
LEFT OUTER JOIN distributions ON distributions.id = line_items.itemizable_id AND line_items.itemizable_type = 'Distribution'
LEFT OUTER JOIN items ON items.id = line_items.item_id
LEFT OUTER JOIN adjustments ON adjustments.id = line_items.itemizable_id AND line_items.itemizable_type = 'Adjustment'
LEFT OUTER JOIN transfers ON transfers.id = line_items.itemizable_id AND line_items.itemizable_type = 'Transfer'")
     .where("(distributions.storage_location_id = :id or (adjustments.storage_location_id= :id and line_items.quantity < 0) or transfers.from_id = :id) and items.organization_id= :organization_id", id: storage_location_id,
                                                                                                                                                                                                      organization_id: organization_id)
     .select("sum( case when line_items.quantity < 0 then -1*line_items.quantity else line_items.quantity END ) as quantity, items.id, items.name")
     .group("items.name, items.id")
     .order("items.name")
  end

  def self.items_out_total(storage_location_id, organization_id)
    joins("
LEFT OUTER JOIN distributions ON distributions.id = line_items.itemizable_id AND line_items.itemizable_type = 'Distribution'
LEFT OUTER JOIN items ON items.id = line_items.item_id
LEFT OUTER JOIN adjustments ON adjustments.id = line_items.itemizable_id AND line_items.itemizable_type = 'Adjustment'
LEFT OUTER JOIN transfers ON transfers.id = line_items.itemizable_id AND line_items.itemizable_type = 'Transfer'")
      .where("(distributions.storage_location_id = :id or (adjustments.storage_location_id= :id and line_items.quantity < 0) or transfers.from_id = :id) and items.organization_id= :organization_id", id: storage_location_id, organization_id: organization_id)
      .sum("case when line_items.quantity < 0 then -1*line_items.quantity else line_items.quantity END")
  end

  def self.items_in(storage_location_id, organization_id)
    joins("
LEFT OUTER JOIN donations ON donations.id = line_items.itemizable_id AND line_items.itemizable_type = 'Donation'
LEFT OUTER JOIN purchases ON purchases.id = line_items.itemizable_id AND line_items.itemizable_type = 'Purchase'
LEFT OUTER JOIN items ON items.id = line_items.item_id
LEFT OUTER JOIN adjustments ON adjustments.id = line_items.itemizable_id AND line_items.itemizable_type = 'Adjustment'
LEFT OUTER JOIN transfers ON transfers.id = line_items.itemizable_id AND line_items.itemizable_type = 'Transfer'")
    .where("(donations.storage_location_id = :id or purchases.storage_location_id = :id or (adjustments.storage_location_id = :id and line_items.quantity > 0) or transfers.to_id = :id)  and items.organization_id = :organization_id", id: storage_location_id, organization_id: organization_id)
    .select("sum(line_items.quantity) as quantity, items.id, items.name")
    .group("items.name, items.id")
    .order("items.name")
  end

  def self.items_in_total(storage_location_id, organization_id)
    joins("
LEFT OUTER JOIN donations ON donations.id = line_items.itemizable_id AND line_items.itemizable_type = 'Donation'
LEFT OUTER JOIN purchases ON purchases.id = line_items.itemizable_id AND line_items.itemizable_type = 'Purchase'
LEFT OUTER JOIN items ON items.id = line_items.item_id
LEFT OUTER JOIN adjustments ON adjustments.id = line_items.itemizable_id AND line_items.itemizable_type = 'Adjustment'
LEFT OUTER JOIN transfers ON transfers.id = line_items.itemizable_id AND line_items.itemizable_type = 'Transfer'")
                      .where("(donations.storage_location_id = :id or purchases.storage_location_id = :id or (adjustments.storage_location_id = :id and line_items.quantity > 0) or transfers.to_id = :id)  and items.organization_id = :organization_id", id: storage_location_id, organization_id: organization_id)
                      .sum("line_items.quantity")
  end
end
