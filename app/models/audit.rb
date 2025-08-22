# == Schema Information
#
# Table name: audits
#
#  id                  :bigint           not null, primary key
#  status              :integer          default("in_progress"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  adjustment_id       :bigint
#  organization_id     :bigint
#  storage_location_id :bigint
#  user_id             :bigint
#

class Audit < ApplicationRecord
  has_paper_trail
  belongs_to :user
  belongs_to :organization
  belongs_to :storage_location
  belongs_to :adjustment, optional: true

  include Exportable
  include Itemizable
  include Filterable
  scope :at_location, ->(location_id) { where(storage_location_id: location_id) }

  accepts_nested_attributes_for :adjustment

  enum :status, { in_progress: 0, confirmed: 1, finalized: 2 }

  validate :line_items_quantity_is_not_negative
  validate :line_items_unique_by_item_id
  validate :user_is_organization_admin_of_the_organization

  def self.finalized_since?(itemizable, *location_ids)
    item_ids = itemizable.line_items.pluck(:item_id)
    where(status: "finalized")
      .where(storage_location_id: location_ids)
      .where(updated_at: itemizable.created_at..)
      .joins(:line_items)
      .where(line_items: {item_id: item_ids})
      .exists?
  end

  def user_is_organization_admin_of_the_organization
    return if organization.nil?

    unless user.has_role?(Role::ORG_ADMIN, organization)
      errors.add :user, "user must be an organization admin of the organization"
    end
  end

  def self.generate_csv_from_inventory(audits, inventory)
    all_items = inventory.all_items.uniq(&:item_id).sort_by(&:name)
    additional_headers = all_items.map(&:name).uniq
    headers = csv_export_headers + additional_headers

    CSV.generate(write_headers: true, headers: headers) do |csv|
      audits.map do |audit|
        sl = audit.storage_location # preloaded earlier with includes to avoid n+1
        total_quantity = inventory.quantity_for(storage_location: sl.id)

        row = [audit.updated_at.strftime("%B %d %Y"), audit.status, sl.name, sl.address, sl.square_footage, sl.warehouse_type, total_quantity] +
          all_items.map { |i| inventory.quantity_for(storage_location: sl.id, item_id: i.item_id) }

        csv << row.map { |attr| normalize_csv_attribute(attr) }
      end
    end
  end

  def self.csv_export_headers
    ["Audit Date", "Audit Status", "Name", "Address", "Square Footage", "Warehouse Type", "Total Inventory"]
  end

  private

  def line_items_unique_by_item_id
    item_ids = line_items.map(&:item_id)
    duplicate_ids = item_ids.select { |i| item_ids.count(i) > 1 }
    if duplicate_ids.any?
      item_names = Item.where(id: duplicate_ids).map(&:name)
      errors.add(:base,
        "You have entered at least one duplicate item: #{item_names.join(", ")}")
    end
  end

  def line_items_quantity_is_not_negative
    line_items_quantity_is_at_least(0)
  end
end
